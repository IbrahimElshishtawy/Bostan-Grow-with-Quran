/// Qibla compass models and calculations
import 'dart:math';

class QiblaDirection {
  const QiblaDirection({
    required this.angle,
    required this.direction,
    required this.distance,
  });

  final double angle; // 0-360 degrees
  final String direction; // N, NE, E, SE, S, SW, W, NW
  final double distance; // km to Kaaba

  String get formattedAngle => '${angle.toStringAsFixed(1)}°';
  String get formattedDistance => '${distance.toStringAsFixed(0)} km';

  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  /// Calculate Qibla direction from user location
  static QiblaDirection calculate({
    required double userLatitude,
    required double userLongitude,
  }) {
    final angle = _calculateQiblaAngle(userLatitude, userLongitude);
    final distance = _calculateDistance(userLatitude, userLongitude);
    final direction = _getDirection(angle);

    return QiblaDirection(
      angle: angle,
      direction: direction,
      distance: distance,
    );
  }

  static double _calculateQiblaAngle(double lat, double lng) {
    final latRad = _toRadians(lat);
    final lngRad = _toRadians(lng);
    final kaabaLatRad = _toRadians(kaabaLatitude);
    final kaabaLngRad = _toRadians(kaabaLongitude);

    final dLng = kaabaLngRad - lngRad;

    final y = sin(dLng) * cos(kaabaLatRad);
    final x = cos(latRad) * sin(kaabaLatRad) -
        sin(latRad) * cos(kaabaLatRad) * cos(dLng);

    var angle = atan2(y, x) * 180.0 / pi;
    angle = (angle + 360) % 360;

    return angle;
  }

  static double _calculateDistance(double lat, double lng) {
    const earthRadius = 6371.0; // km

    final latRad = _toRadians(lat);
    final lngRad = _toRadians(lng);
    final kaabaLatRad = _toRadians(kaabaLatitude);
    final kaabaLngRad = _toRadians(kaabaLongitude);

    final dLat = kaabaLatRad - latRad;
    final dLng = kaabaLngRad - lngRad;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latRad) * cos(kaabaLatRad) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static String _getDirection(double angle) {
    if (angle >= 337.5 || angle < 22.5) return 'N';
    if (angle >= 22.5 && angle < 67.5) return 'NE';
    if (angle >= 67.5 && angle < 112.5) return 'E';
    if (angle >= 112.5 && angle < 157.5) return 'SE';
    if (angle >= 157.5 && angle < 202.5) return 'S';
    if (angle >= 202.5 && angle < 247.5) return 'SW';
    if (angle >= 247.5 && angle < 292.5) return 'W';
    return 'NW';
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}

class CompassReading {
  const CompassReading({
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  final double heading; // 0-360 degrees
  final double accuracy; // in degrees
  final DateTime timestamp;

  bool get isAccurate => accuracy < 15; // Less than 15 degrees error
  String get formattedHeading => '${heading.toStringAsFixed(1)}°';
  String get formattedAccuracy => '±${accuracy.toStringAsFixed(1)}°';

  CompassReading copyWith({
    double? heading,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return CompassReading(
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class QiblaCompassState {
  const QiblaCompassState({
    required this.qiblaDirection,
    required this.compassReading,
    required this.relativeAngle,
    required this.isCalibrated,
    required this.isLoading,
    this.error,
  });

  final QiblaDirection qiblaDirection;
  final CompassReading compassReading;
  final double relativeAngle; // Angle between compass heading and Qibla
  final bool isCalibrated;
  final bool isLoading;
  final String? error;

  bool get isPointingToQibla => relativeAngle.abs() < 15; // Within 15 degrees

  QiblaCompassState copyWith({
    QiblaDirection? qiblaDirection,
    CompassReading? compassReading,
    double? relativeAngle,
    bool? isCalibrated,
    bool? isLoading,
    String? error,
  }) {
    return QiblaCompassState(
      qiblaDirection: qiblaDirection ?? this.qiblaDirection,
      compassReading: compassReading ?? this.compassReading,
      relativeAngle: relativeAngle ?? this.relativeAngle,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QiblaCalibration {
  const QiblaCalibration({
    required this.isRequired,
    required this.instruction,
    required this.progress,
  });

  final bool isRequired;
  final String instruction;
  final double progress; // 0-1

  static const List<String> calibrationInstructions = [
    'Move your device in a figure-8 pattern',
    'Rotate your device slowly in all directions',
    'Point your device up and down',
    'Calibration complete!',
  ];

  QiblaCalibration copyWith({
    bool? isRequired,
    String? instruction,
    double? progress,
  }) {
    return QiblaCalibration(
      isRequired: isRequired ?? this.isRequired,
      instruction: instruction ?? this.instruction,
      progress: progress ?? this.progress,
    );
  }
}
