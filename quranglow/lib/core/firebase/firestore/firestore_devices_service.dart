import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreDevicesService {
  final FirebaseFirestore _firestore;

  FirestoreDevicesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _devicesRef(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.devices);
  }

  Future<void> registerOrUpdateDevice({
    required String uid,
    required String deviceId,
    required String platform,
    required String appVersion,
    String? fcmToken,
    String? locale,
    String? timezone,
    String? deviceModel,
    String? osVersion,
  }) async {
    final payload = {
      'deviceId': deviceId,
      'platform': platform,
      'appVersion': appVersion,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmToken': ?fcmToken,
      'locale': ?locale,
      'timezone': ?timezone,
      'deviceModel': ?deviceModel,
      'osVersion': ?osVersion,
    };

    await _devicesRef(uid).doc(deviceId).set(payload, SetOptions(merge: true));
  }

  Future<void> removeDevice(String uid, String deviceId) async {
    await _devicesRef(uid).doc(deviceId).delete();
  }
}
