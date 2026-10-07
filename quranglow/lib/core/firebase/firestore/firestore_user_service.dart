import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreUserService {
  final FirebaseFirestore _firestore;

  FirestoreUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid);
  }

  /// Get or create user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _userRef(uid).get();
    return doc.data();
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    payload['lastActiveAt'] = FieldValue.serverTimestamp();
    await _userRef(uid).set(payload, SetOptions(merge: true));
  }

  /// Stream user profile
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _userRef(uid).snapshots().map((snap) => snap.data());
  }

  /// App Preferences
  Future<Map<String, dynamic>?> getAppPreferences(String uid) async {
    final doc = await _userRef(uid)
        .collection(FirestoreCollections.preferences)
        .doc(FirestoreCollections.docAppPreferences)
        .get();
    return doc.data();
  }

  Future<void> saveAppPreferences(String uid, Map<String, dynamic> prefs) async {
    final payload = Map<String, dynamic>.from(prefs);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _userRef(uid)
        .collection(FirestoreCollections.preferences)
        .doc(FirestoreCollections.docAppPreferences)
        .set(payload, SetOptions(merge: true));
  }

  /// Audio Preferences
  Future<Map<String, dynamic>?> getAudioPreferences(String uid) async {
    final doc = await _userRef(uid)
        .collection(FirestoreCollections.preferences)
        .doc(FirestoreCollections.docAudioPreferences)
        .get();
    return doc.data();
  }

  Future<void> saveAudioPreferences(String uid, Map<String, dynamic> prefs) async {
    final payload = Map<String, dynamic>.from(prefs);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _userRef(uid)
        .collection(FirestoreCollections.preferences)
        .doc(FirestoreCollections.docAudioPreferences)
        .set(payload, SetOptions(merge: true));
  }

  /// Notification Preferences
  Future<Map<String, dynamic>?> getNotificationPreferences(String uid) async {
    final doc = await _userRef(uid)
        .collection(FirestoreCollections.preferences)
        .doc(FirestoreCollections.docNotificationPreferences)
        .get();
    return doc.data();
  }

  Future<void> saveNotificationPreferences(String uid, Map<String, dynamic> prefs) async {
    final payload = Map<String, dynamic>.from(prefs);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _userRef(uid)
        .collection(FirestoreCollections.preferences)
        .doc(FirestoreCollections.docNotificationPreferences)
        .set(payload, SetOptions(merge: true));
  }

  /// Streak stream (read-only for clients, updated by server engine)
  Stream<Map<String, dynamic>?> streamStreak(String uid) {
    return _userRef(uid)
        .collection(FirestoreCollections.statistics)
        .doc(FirestoreCollections.docStreak)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Daily Goals
  Future<Map<String, dynamic>?> getDailyGoals(String uid) async {
    final doc = await _userRef(uid)
        .collection(FirestoreCollections.goals)
        .doc(FirestoreCollections.docDailyGoals)
        .get();
    return doc.data();
  }

  Future<void> saveDailyGoals(String uid, Map<String, dynamic> goals) async {
    final payload = Map<String, dynamic>.from(goals);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _userRef(uid)
        .collection(FirestoreCollections.goals)
        .doc(FirestoreCollections.docDailyGoals)
        .set(payload, SetOptions(merge: true));
  }

  /// Daily Activity for date
  Stream<Map<String, dynamic>?> streamDailyActivity(String uid, String date) {
    return _userRef(uid)
        .collection(FirestoreCollections.dailyActivity)
        .doc(date)
        .snapshots()
        .map((snap) => snap.data());
  }
}
