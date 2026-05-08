// ignore_for_file: dangling_library_doc_comments

/// Qibla direction and compass Riverpod providers
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quranglow/core/providers/location_providers.dart';

/// Calculate Qibla direction based on location (latitude, longitude)
/// Returns bearing in degrees (0-360) where 0 = North, 90 = East, 180 = South, 270 = West
final qiblaDirectionProvider = Provider.family<double?, Position?>((
  ref,
  position,
) {
  if (position == null) return null;

  try {
    // Kaaba coordinates
    const double kaabaLat = 21.4225;
    const double kaabaLon = 39.8262;

    final lat1 = position.latitude * (math.pi / 180);
    final lon1 = position.longitude * (math.pi / 180);
    final lat2 = kaabaLat * (math.pi / 180);
    final lon2 = kaabaLon * (math.pi / 180);

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x) * (180 / math.pi);
    bearing = (bearing + 360) % 360;

    return bearing;
  } catch (e) {
    return null;
  }
});

/// Stream of device heading/bearing (from compass)
final compassHeadingProvider = StreamProvider<double>((ref) async* {
  try {
    await for (final event in FlutterCompass.events ?? Stream.empty()) {
      if (event.heading != null) {
        yield event.heading!;
      }
    }
  } catch (e) {
    // Device doesn't support compass or permission denied
  }
});

/// Calculate angle between device heading and Qibla direction
final qiblaAngleProvider = Provider<double>((ref) {
  final compassHeadingAsync = ref.watch(compassHeadingProvider);
  final positionAsync = ref.watch(userPositionProvider);

  return compassHeadingAsync.when(
    data: (compassHeading) {
      return positionAsync.when(
        data: (position) {
          final qiblaDir = ref.watch(qiblaDirectionProvider(position));
          if (qiblaDir == null) return 0;

          var angle = qiblaDir - compassHeading;
          // Normalize to -180 to 180
          while (angle > 180) {
            angle -= 360;
          }
          while (angle < -180) {
            angle += 360;
          }

          return angle;
        },
        error: (error, stackTrace) => 0,
        loading: () => 0,
      );
    },
    error: (error, stackTrace) => 0,
    loading: () => 0,
  );
});

/// Check if user is facing Qibla (within 20 degree tolerance)
final isFacingQiblaProvider = Provider<bool>((ref) {
  final angle = ref.watch(qiblaAngleProvider);
  return angle.abs() < 20;
});
