import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentOnce() async {
    if (!await ensurePermission()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 7),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  void startStream(void Function(Position) onData) async {
    if (!await ensurePermission()) return;
    _sub ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen(onData);
  }

  Future<void> stopStream() async {
    await _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    _sub?.cancel();
  }
}
