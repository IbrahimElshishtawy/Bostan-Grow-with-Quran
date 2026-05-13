import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';

class MosqueData {
  final String name;
  final LatLng location;
  final double distanceKm;

  MosqueData({required this.name, required this.location, required this.distanceKm});
}

class NearestMosqueScreen extends StatefulWidget {
  const NearestMosqueScreen({super.key});

  @override
  State<NearestMosqueScreen> createState() => _NearestMosqueScreenState();
}

class _NearestMosqueScreenState extends State<NearestMosqueScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  Position? _currentPos;
  bool _isLoading = true;
  String? _errorMsg;
  List<MosqueData> _mosques = [];
  
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
      
      // 2. Fetch Mosques using OpenStreetMap Overpass API (Free, No API Keys!)
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
    try {
      final dio = Dio();
      // Radius: 5000 meters (5km)
      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="place_of_worship"]["religion"="muslim"](around:5000,${pos.latitude},${pos.longitude});
          way["amenity"="place_of_worship"]["religion"="muslim"](around:5000,${pos.latitude},${pos.longitude});
        );
        out center;
      ''';

      final response = await dio.post(
        'https://overpass-api.de/api/interpreter',
        data: query,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final elements = response.data['elements'] as List<dynamic>?;
      if (elements == null) throw Exception('لا توجد مساجد في النطاق القريب.');

      final List<MosqueData> found = [];
      for (var el in elements) {
        double lat = el['lat'] ?? el['center']?['lat'] ?? 0.0;
        double lon = el['lon'] ?? el['center']?['lon'] ?? 0.0;
        if (lat == 0.0 || lon == 0.0) continue;

        String name = el['tags']?['name'] ?? el['tags']?['name:ar'] ?? 'مسجد قريب';

        double distance = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, lat, lon
        );

        found.add(MosqueData(
          name: name,
          location: LatLng(lat, lon),
          distanceKm: distance / 1000.0,
        ));
      }

      // Sort by distance
      found.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (mounted) {
        setState(() {
          _mosques = found;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = 'تعذر الاتصال بالخادم للبحث عن المساجد.';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMosque(MosqueData mosque) async {
    HapticFeedback.selectionClick();
    // Launch Google Maps App externally for routing
    final uri = Uri.parse('google.navigation:q=${mosque.location.latitude},${mosque.location.longitude}&mode=w');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to browser mapping if no maps app
      final fallbackUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${mosque.location.latitude},${mosque.location.longitude}&travelmode=walking');
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
          width: 50,
          height: 50,
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
                      BoxShadow(color: cs.shadow.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: cs.shadow.withValues(alpha: 0.2), blurRadius: 2),
                    ],
                  ),
                  child: Text(
                    m.name.length > 12 ? '${m.name.substring(0, 10)}..' : m.name,
                    style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
              urlTemplate: isDark 
                  ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.quranglow.app',
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
              label: const Text('بدء التوجيه', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _navigateToMosque(closest),
            ),
          ),
        ],
      ),
    );
  }
}
