import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firestore/firestore_devices_service.dart';

class MessagingService {
  final FirebaseMessaging _messaging;
  final FirestoreDevicesService _devicesService;

  MessagingService({
    FirebaseMessaging? messaging,
    FirestoreDevicesService? devicesService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _devicesService = devicesService ?? FirestoreDevicesService();

  Future<void> initialize({required String uid, required String deviceId}) async {
    try {
      // 1. Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Fetch FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          await _devicesService.registerOrUpdateDevice(
            uid: uid,
            deviceId: deviceId,
            platform: 'android', // Or Platform.operatingSystem
            appVersion: '1.0.0',
            fcmToken: token,
          );
        }

        // 3. Listen to token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _devicesService.registerOrUpdateDevice(
            uid: uid,
            deviceId: deviceId,
            platform: 'android',
            appVersion: '1.0.0',
            fcmToken: newToken,
          );
        });
      }
    } catch (e) {
      dev.log('Messaging initialization error: $e', name: 'MessagingService');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      dev.log('Failed to subscribe to topic $topic: $e', name: 'MessagingService');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      dev.log('Failed to unsubscribe from topic $topic: $e', name: 'MessagingService');
    }
  }
}
