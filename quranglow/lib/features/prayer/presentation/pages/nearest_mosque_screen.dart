import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';

class MosqueData {
  final String name;
  final LatLng location;
  final double distanceKm;

  MosqueData({required this.name, required this.location, required this.distanceKm});
}

class NearestMosqueScreen extends ConsumerStatefulWidget {
  const NearestMosqueScreen({super.key});

  @override
  ConsumerState<NearestMosqueScreen> createState() => _NearestMosqueScreenState();
}

class _NearestMosqueScreenState extends ConsumerState<NearestMosqueScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  Position? _currentPos;
  bool _isLoading = true;
  String? _errorMsg;
  List<MosqueData> _mosques = [];
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  MosqueData? _selectedMosque;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initMap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      // 1. Get Location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('خدمة تحديد الموقع معطلة. يرجى تفعيلها.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('صلاحية الموقع مرفوضة.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('صلاحيات الموقع مرفوضة دائماً. يرجى تعديلها من الإعدادات.');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPos = pos;
      
      // 2. Fetch Mosques
      await _fetchMosques(pos);

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMosques(Position pos) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final dio = Dio();
      final List<MosqueData> found = [];
      bool googleSuccess = false;

      // --- 1. Google Places API ---
      try {
        const apiKey = 'AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao';
        final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
            '?location=${pos.latitude},${pos.longitude}'
            '&radius=10000&type=mosque&keyword=مسجد|masjid|prayer|مصلى|زاوية&language=ar&key=$apiKey';

        final response = await dio.get(
          url,
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
            validateStatus: (status) => true,
          ),
        );

        final status = response.data?['status'] as String?;
        if (response.statusCode == 200 && (status == 'OK' || status == 'ZERO_RESULTS')) {
          final results = response.data?['results'] as List<dynamic>? ?? [];
          for (var el in results) {
            final loc = el['geometry']?['location'];
            if (loc == null) continue;
            double lat = loc['lat']?.toDouble() ?? 0.0;
            double lon = loc['lng']?.toDouble() ?? 0.0;
            if (lat == 0 || lon == 0) continue;
            String name = el['name'] ?? 'مسجد';
            double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon);
            found.add(MosqueData(name: name, location: LatLng(lat, lon), distanceKm: dist / 1000.0));
          }
          googleSuccess = true;
        }
      } catch (e) {
        debugPrint('Google API failed: $e');
      }

      // --- 2. Fallback: Parallel Race (Nominatim vs Overpass Mirror) ---
      if (!googleSuccess || found.isEmpty) {
        try {
          debugPrint('Starting Parallel Race for fallback...');
          
          final nominatimUrl = 'https://nominatim.openstreetmap.org/search?q=mosque+masjid+مصلى&format=json&lat=${pos.latitude}&lon=${pos.longitude}&limit=30';
          final overpassUrl = 'https://lz4.overpass-api.de/api/interpreter';
          // Search for nodes, ways, and relations (nwr) and include both amenity=mosque and religion=muslim
          final overpassData = 'data=${Uri.encodeQueryComponent('[out:json][timeout:15];nwr(around:10000,${pos.latitude},${pos.longitude})["amenity"~"place_of_worship|mosque"]["religion"="muslim"];out center;')}' ;

          final results = await Future.wait([
            dio.get(nominatimUrl, options: Options(
              sendTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'User-Agent': 'QuranGlow_App/1.0'},
            )).then((r) => _parseNominatim(r.data, pos)).catchError((_) => <MosqueData>[]),
            
            dio.post(overpassUrl, data: overpassData, options: Options(
              sendTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'QuranGlow_App/1.0',
              },
            )).then((r) => _parseOverpass(r.data, pos)).catchError((_) => <MosqueData>[]),
          ]);

          final allFound = [...results[0], ...results[1]];
          final seen = <String>{};
          for (var m in allFound) {
            if (seen.add('${m.location.latitude},${m.location.longitude}')) {
              found.add(m);
            }
          }
        } catch (e) {
          debugPrint('Parallel Race failed: $e');
        }
      }

      if (found.isEmpty) {
        throw Exception('لم نتمكن من العثور على مساجد قريبة حالياً.');
      }

      found.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      if (mounted) {
        setState(() {
          _mosques = found;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<MosqueData> _parseNominatim(dynamic data, Position pos) {
    final List<MosqueData> list = [];
    if (data is List) {
      for (var el in data) {
        double lat = double.tryParse(el['lat']?.toString() ?? '') ?? 0.0;
        double lon = double.tryParse(el['lon']?.toString() ?? '') ?? 0.0;
        if (lat == 0 || lon == 0) continue;
        String name = el['display_name']?.split(',').first ?? 'مسجد';
        double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon);
        list.add(MosqueData(name: name, location: LatLng(lat, lon), distanceKm: dist / 1000.0));
      }
    }
    return list;
  }

  List<MosqueData> _parseOverpass(dynamic data, Position pos) {
    final List<MosqueData> list = [];
    if (data is Map && data['elements'] != null) {
      final elements = data['elements'] as List<dynamic>;
      for (var el in elements) {
        // Use center if it's a way/relation, otherwise lat/lon
        double lat = (el['lat'] ?? el['center']?['lat'])?.toDouble() ?? 0.0;
        double lon = (el['lon'] ?? el['center']?['lng'] ?? el['center']?['lon'])?.toDouble() ?? 0.0;
        if (lat == 0 || lon == 0) continue;
        
        String name = (el['tags']?['name:ar'] ?? el['tags']?['name'] ?? 'مسجد').toString();
        double dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon);
        list.add(MosqueData(name: name, location: LatLng(lat, lon), distanceKm: dist / 1000.0));
      }
    }
    return list;
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_currentPos == null) return;
    
    setState(() {
      _isFetchingRoute = true;
      _routePoints = [];
    });
    
    try {
      final dio = Dio();
      // Use OSRM for free walking route
      final url = 'https://router.project-osrm.org/route/v1/walking/'
          '${_currentPos!.longitude},${_currentPos!.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';
      
      final response = await dio.get(url);
      
      if (response.statusCode == 200 && response.data['routes'] != null) {
        final List<dynamic> coords = response.data['routes'][0]['geometry']['coordinates'];
        final points = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        
        setState(() {
          _routePoints = points;
        });

        // Fit map to show both user and mosque
        if (points.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints([
            LatLng(_currentPos!.latitude, _currentPos!.longitude),
            destination,
            ...points,
          ]);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        }
      }
    } catch (e) {
      debugPrint('Route fetch failed: $e');
    } finally {
      setState(() => _isFetchingRoute = false);
    }
  }

  void _navigateToMosque(MosqueData mosque) async {
    HapticFeedback.selectionClick();
    
    // If route isn't shown yet, show it first
    if (_routePoints.isEmpty || _selectedMosque != mosque) {
      _selectedMosque = mosque;
      await _getRoute(mosque.location);
      return;
    }

    // If route is already shown, open external maps for real turn-by-turn
    final uri = Uri.parse('google.navigation:q=${mosque.location.latitude},${mosque.location.longitude}&mode=w');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to browser mapping if no maps app
      final fallbackUri = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${_currentPos?.latitude},${_currentPos?.longitude}&destination=${mosque.location.latitude},${mosque.location.longitude}&travelmode=walking');
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const ProAppBar(
          title: 'أقرب المساجد',
          subtitle: 'خريطة تفاعلية للمساجد المحيطة بك',
        ),
        body: _buildBody(cs, isDark),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, bool isDark) {
    final isOnlineAsync = ref.watch(isOnlineProvider);
    final isOnline = isOnlineAsync.value ?? true;
    if (!isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: cs.primary.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'من فضلك قم بتشغيل الإنترنت للوصول إلى كامل المحتوى والتحميل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontFamily: 'Tajawal',
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'جاري تحديد موقعك والبحث عن المساجد...',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMsg != null || _currentPos == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, size: 64, color: cs.error),
              const SizedBox(height: 16),
              Text(
                'تعذر تحديد المساجد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.error,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMsg ?? 'حدث خطأ غير متوقع.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontFamily: 'Tajawal',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _initMap,
              ),
            ],
          ),
        ),
      );
    }

    // Build Map Markers
    final userLocation = LatLng(_currentPos!.latitude, _currentPos!.longitude);
    final markers = <Marker>[
      // User Marker
      Marker(
        point: userLocation,
        width: 60,
        height: 60,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 30 + (30 * _pulseController.value),
                  height: 30 + (30 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.3 * (1.0 - _pulseController.value)),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: cs.shadow.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Mosque Markers
      ..._mosques.map((m) {
        return Marker(
          point: m.location,
          width: 60,
          height: 80, // Increased height to prevent overflow
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _navigateToMosque(m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  constraints: const BoxConstraints(maxWidth: 60),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    m.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.black,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];

    return Stack(
      children: [
        // Internal Native Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 10.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.quranglow.app',
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            PolylineLayer(
              polylines: [
                if (_routePoints.isNotEmpty)
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderColor: Colors.blue.shade900,
                    borderStrokeWidth: 1,
                  ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Bottom Results Panel
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: _mosques.isEmpty 
              ? const SizedBox.shrink()
              : _buildMosqueBottomSheet(cs),
        ),

        // FAB to Recenter
        Positioned(
          bottom: 120,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () {
              _mapController.move(userLocation, 15.0);
            },
            backgroundColor: cs.surface,
            foregroundColor: cs.primary,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildMosqueBottomSheet(ColorScheme cs) {
    final closest = _mosques.first;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 1.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.mosque_rounded, color: Colors.teal.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أقرب مسجد إليك',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    Text(
                      closest.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(closest.distanceKm * 1000).toInt()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                  const Text(
                    'متر',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_walk_rounded),
              label: Text(
                _isFetchingRoute 
                    ? 'جاري رسم المسار...' 
                    : (_routePoints.isNotEmpty && _selectedMosque == closest ? 'بدء التنقل الفعلي' : 'رسم مسار الطريق'), 
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _routePoints.isNotEmpty && _selectedMosque == closest ? Colors.blue.shade700 : cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isFetchingRoute ? null : () => _navigateToMosque(closest),
            ),
          ),
        ],
      ),
    );
  }
}
