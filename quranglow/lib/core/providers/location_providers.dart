/// Location and Geolocation Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Check if location services are enabled
final locationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  return await Geolocator.isLocationServiceEnabled();
});

/// Check location permissions
final locationPermissionProvider = FutureProvider<LocationPermission>((
  ref,
) async {
  return await Geolocator.checkPermission();
});

/// Request location permissions
final requestLocationPermissionProvider = FutureProvider<LocationPermission>((
  ref,
) async {
  return await Geolocator.requestPermission();
});

/// Get current user position
final userPositionProvider = FutureProvider<Position?>((ref) async {
  try {
    // Check if service is enabled
    final isEnabled = await ref.watch(locationServiceEnabledProvider.future);
    if (!isEnabled) {
      return null;
    }

    // Check permission
    var permission = await ref.watch(locationPermissionProvider.future);

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 30),
    );

    return position;
  } catch (e) {
    return null;
  }
});

/// Get user latitude and longitude as tuple
final userCoordinatesProvider = Provider.family<(double, double)?, Position?>((
  ref,
  position,
) {
  if (position == null) return null;
  return (position.latitude, position.longitude);
});

/// Stream of position changes (for real-time location updates)
final positionStreamProvider = StreamProvider<Position>((ref) async* {
  try {
    final isEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isEnabled) {
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );

    await for (final position in positionStream) {
      yield position;
    }
  } catch (e) {
    // Silently handle errors
  }
});
