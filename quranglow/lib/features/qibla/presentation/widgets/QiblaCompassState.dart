import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quranglow/features/qibla/presentation/widgets/burning_effect_painter.dart';
import 'package:quranglow/features/qibla/presentation/widgets/compass_dial.dart'
    as dial;
import 'package:quranglow/features/qibla/presentation/widgets/info_row.dart'
    as info;
import 'package:quranglow/features/qibla/presentation/widgets/loading_error.dart';
import 'package:quranglow/features/qibla/presentation/widgets/qibla_arrow.dart';
import 'package:quranglow/features/qibla/presentation/widgets/qibla_compass.dart';

class QiblaCompassState extends State<QiblaCompass>
    with SingleTickerProviderStateMixin {
  static const _kaabaLat = 21.4225;
  static const _kaabaLng = 39.8262;

  late AnimationController _animationController;

  Position? _pos;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _sensorCheckTimer;

  String _sensorStatus = '—';
  bool _usingCourse = false;
  double? _heading;
  double? _smoothedHeading;
  double? _bearingToQibla;
  double? _delta;
  String? _error;

  int _initSeq = 0;

  // Manual mode for damaged / missing sensors
  bool _sensorMissing = false;
  bool _isManualMode = false;
  double _manualHeading = 0.0; // Simulated heading set by dragging dial

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sensorCheckTimer?.cancel();
    _cancelStreams();
    super.dispose();
  }

  void _cancelStreams() {
    _posSub?.cancel();
    _posSub = null;
    _compassSub?.cancel();
    _compassSub = null;
  }

  void _safeSet(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _init() async {
    final seq = ++_initSeq;
    _cancelStreams();
    _sensorCheckTimer?.cancel();
    _usingCourse = false;
    _sensorMissing = false;
    _sensorStatus = '—';
    _heading = _smoothedHeading = _delta = null;
    _error = null;

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (seq != _initSeq || !mounted) return;
      if (!enabled) {
        _safeSet(() => _error = 'فعّل خدمة الموقع ثم أعد المحاولة.');
        return;
      }

      LocationPermission p = await Geolocator.checkPermission();
      if (seq != _initSeq || !mounted) return;
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (seq != _initSeq || !mounted) return;
      if (p == LocationPermission.deniedForever ||
          p == LocationPermission.denied) {
        _safeSet(() => _error = 'صلاحية الموقع مرفوضة.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (seq != _initSeq || !mounted) return;
      _pos = pos;
      _bearingToQibla = _bearing(
        pos.latitude,
        pos.longitude,
        _kaabaLat,
        _kaabaLng,
      );
      _safeSet(() {});

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 2,
        ),
      ).listen((p) {
        if (!mounted || seq != _initSeq) return;
        _pos = p;
        _bearingToQibla = _bearing(p.latitude, p.longitude, _kaabaLat, _kaabaLng);

        if (!_isManualMode && (_usingCourse || _heading == null)) {
          if (p.speed > 1.0 && p.heading >= 0) {
            final course = _normalize(p.heading);
            _usingCourse = true;
            _sensorStatus = 'COURSE';
            _applyHeading(course);
          }
        }

        _updateDelta();
        _safeSet(() {});
      });

      // Set detection timer for missing/broken magnetometer
      _sensorCheckTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _heading == null && !_usingCourse) {
          _safeSet(() {
            _sensorMissing = true;
            // Enable manual mode automatically if we determine the sensor gives no data
            _isManualMode = true;
            _updateDelta();
          });
        }
      });

      _compassSub = FlutterCompass.events?.listen((e) {
        if (!mounted || seq != _initSeq) return;

        // We received data, cancel missing sensor trigger
        _sensorCheckTimer?.cancel();
        if (_sensorMissing) {
          _safeSet(() => _sensorMissing = false);
        }

        final acc = e.accuracy;
        if (acc == null) {
          _sensorStatus = 'UNKNOWN';
        } else {
          final needsCalib = (acc <= 1) || (acc < 0) || (acc > 15);
          _sensorStatus = needsCalib ? 'CALIBRATION' : 'OK';
        }

        if (e.heading != null) {
          _usingCourse = false;
          _applyHeading(_normalize(e.heading!));
          _updateDelta();
          _safeSet(() {});
        }
      });
    } catch (e) {
      if (seq != _initSeq || !mounted) return;
      _safeSet(() => _error = 'حدث خطأ أثناء تشغيل البوصلة: $e');
    }
  }

  void _applyHeading(double h) {
    _heading = h;
    _smoothedHeading = (_smoothedHeading == null)
        ? h
        : (_smoothedHeading! * 0.85 + h * 0.15);
  }

  void _updateDelta() {
    final src = _isManualMode ? _manualHeading : (_smoothedHeading ?? _heading);
    if (src == null || _bearingToQibla == null) return;
    _delta = _normalize(_bearingToQibla! - src);
  }

  double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final q1 = _deg2rad(lat1);
    final q2 = _deg2rad(lat2);
    final s = _deg2rad(lon2 - lon1);
    final y = math.sin(s) * math.cos(q2);
    final x =
        math.cos(q1) * math.sin(q2) - math.sin(q1) * math.cos(q2) * math.cos(s);
    return _normalize(_rad2deg(math.atan2(y, x)));
  }

  double _deg2rad(double d) => d * math.pi / 180.0;
  double _rad2deg(double r) => r * 180.0 / math.pi;
  double _normalize(double deg) {
    var d = deg % 360;
    if (d < 0) d += 360;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_error != null) {
      return ErrorCard(message: _error!, onRetry: _init);
    }
    if (_pos == null) {
      return const LoadingCard();
    }

    final heading = _isManualMode 
        ? _manualHeading 
        : ((_smoothedHeading ?? _heading) ?? 0);
    final delta = _delta ?? 0;

    // Build premium contextual hints based on active system state
    String hint;
    Color hintColor;
    if (_isManualMode) {
      hint = _sensorMissing
          ? 'مستشعر الاتجاه غير متوفر. استخدم أصبعك لتدوير القرص ومحاذاة حرف N مع جهة الشمال الحقيقية.'
          : 'وضع التوجيه اليدوي نشط. قم بتدوير البوصلة يدويًا لمحاذاة الاتجاه.';
      hintColor = cs.primary;
    } else if (_usingCourse) {
      hint = 'يتم التوجيه اعتمادًا على حركة نظام الـ GPS، تحرك لزيادة الدقة.';
      hintColor = cs.tertiary;
    } else {
      hint = (_sensorStatus == 'CALIBRATION')
          ? 'حرّك الهاتف بشكل 8 وابتعد عن المعادن لتحسين دقة البوصلة.'
          : 'ثبّت الهاتف أفقيًا ووجّه السهم حتى يتطابق مع اتجاه القبلة.';
      hintColor = (_sensorStatus == 'CALIBRATION' ? cs.tertiary : cs.onSurfaceVariant);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.surface, cs.surfaceContainerHigh],
            ),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StatusChip(
                    icon: _isManualMode 
                        ? Icons.touch_app_rounded
                        : (_usingCourse ? Icons.my_location_rounded : Icons.sensors_rounded),
                    text: _isManualMode 
                        ? 'توجيه يدوي' 
                        : (_usingCourse ? 'وضع GPS' : 'وضع البوصلة'),
                  ),
                  const Spacer(),
                  // Quick switch button for manual rotation fallback
                  InkWell(
                    onTap: () {
                      _safeSet(() {
                        _isManualMode = !_isManualMode;
                        _updateDelta();
                      });
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isManualMode 
                            ? cs.primaryContainer.withValues(alpha: 0.5)
                            : Colors.transparent,
                        border: Border.all(
                          color: _isManualMode ? cs.primary : cs.outlineVariant,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isManualMode ? Icons.auto_mode_rounded : Icons.edit_location_alt_rounded,
                            size: 14,
                            color: _isManualMode ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isManualMode ? 'تلقائي' : 'يدوي',
                            style: TextStyle(
                              color: _isManualMode ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_isManualMode) ...[
                    const SizedBox(width: 8),
                    Text(
                      'الدقة: ${_statusLabel(_sensorStatus)}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Trigonometry-powered polar tracking for premium manual dial manipulation
                      onPanUpdate: _isManualMode ? (details) {
                        final box = context.findRenderObject() as RenderBox;
                        final center = box.size.center(Offset.zero);
                        final touchVec = details.localPosition - center;
                        
                        // Calculate relative angle (radians) and convert to compass-relative degrees
                        final rad = math.atan2(touchVec.dy, touchVec.dx);
                        _safeSet(() {
                          // Add 90 degrees buffer to lock trig plane (0 to right) into compass plane (0 to top)
                          _manualHeading = _normalize(_rad2deg(rad) + 90);
                          _updateDelta();
                        });
                      } : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          dial.CompassDial(
                            rotationDeg: heading,
                            ringsColor: cs.outlineVariant,
                          ),
                          if (widget.showEffects)
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: Size.infinite,
                                  painter: BurningEffectPainter(
                                    rotation: delta,
                                    color: cs.primary,
                                    animationValue: _animationController.value,
                                  ),
                                );
                              },
                            ),
                          QiblaArrow(rotationDeg: delta, color: cs.primary),
                          // Hand/Touch helper indicator when in manual mode
                          if (_isManualMode)
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: cs.primary.withValues(alpha: 0.6 * (1.0 - _animationController.value)),
                                        width: 2 + (4 * _animationController.value),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.showInfoCards) ...[
          info.InfoRow(
            heading: _isManualMode ? _manualHeading : (_smoothedHeading ?? _heading),
            bearing: _bearingToQibla,
            delta: _delta,
          ),
          const SizedBox(height: 10),
        ],
        // If sensor is determined to be physically unavailable or broken, render direct reassurance banner
        if (_sensorMissing && _isManualMode)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: cs.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                            child: Text(
                              'تم كشف عطل بحساس الاتجاهات، تم تفعيل وضع التوجيه اليدوي البديل كحل دائم.',
                              style: TextStyle(
                                color: cs.onErrorContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
        if (widget.showCalibrationCard && !_isManualMode) ...[
          CalibrationCard(status: _sensorStatus == 'CALIBRATION' ? 'WARN' : 'OK'),
          const SizedBox(height: 10),
        ],
        if (widget.showHintCard)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Text(
              hint,
              style: TextStyle(
                color: hintColor,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'OK':
        return 'ممتازة';
      case 'CALIBRATION':
        return 'تحتاج معايرة';
      case 'COURSE':
        return 'GPS';
      default:
        return 'غير محددة';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cs.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}
