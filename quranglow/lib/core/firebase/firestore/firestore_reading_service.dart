import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreReadingService {
  final FirebaseFirestore _firestore;
  Timer? _debounceTimer;

  FirestoreReadingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid);
  }

  /// Get current cloud reading progress
  Future<Map<String, dynamic>?> getReadingProgress(String uid) async {
    final doc = await _userRef(uid)
        .collection(FirestoreCollections.reading)
        .doc(FirestoreCollections.docReadingProgress)
        .get();
    return doc.data();
  }

  /// Save reading progress with debouncing (Cost Control - Section 9 & 57)
  void saveReadingProgressDebounced({
    required String uid,
    required int currentPage,
    required int currentSurah,
    required int currentAyah,
    required int currentJuz,
    String? lastSessionId,
    Duration delay = const Duration(seconds: 4),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      await saveReadingProgress(
        uid: uid,
        currentPage: currentPage,
        currentSurah: currentSurah,
        currentAyah: currentAyah,
        currentJuz: currentJuz,
        lastSessionId: lastSessionId,
      );
    });
  }

  /// Immediate save of reading progress
  Future<void> saveReadingProgress({
    required String uid,
    required int currentPage,
    required int currentSurah,
    required int currentAyah,
    required int currentJuz,
    String? lastSessionId,
  }) async {
    await _userRef(uid)
        .collection(FirestoreCollections.reading)
        .doc(FirestoreCollections.docReadingProgress)
        .set({
      'currentPage': currentPage,
      'currentSurah': currentSurah,
      'currentAyah': currentAyah,
      'currentJuz': currentJuz,
      'lastReadAt': FieldValue.serverTimestamp(),
      'lastSessionId': ?lastSessionId,
    }, SetOptions(merge: true));
  }

  /// Save a completed reading session
  Future<void> saveReadingSession({
    required String uid,
    required String sessionId,
    required Map<String, dynamic> sessionData,
  }) async {
    final payload = Map<String, dynamic>.from(sessionData);
    payload['createdAt'] = FieldValue.serverTimestamp();
    await _userRef(uid)
        .collection(FirestoreCollections.readingSessions)
        .doc(sessionId)
        .set(payload, SetOptions(merge: true));
  }

  /// Query recent reading sessions
  Future<List<Map<String, dynamic>>> getRecentSessions(String uid, {int limit = 20}) async {
    final snap = await _userRef(uid)
        .collection(FirestoreCollections.readingSessions)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => d.data()).toList();
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
