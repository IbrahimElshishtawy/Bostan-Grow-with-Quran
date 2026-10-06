import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class FirestoreCacheService {
  final FirebaseService _firebaseService;

  FirestoreCacheService({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Fetch a document prioritizing local offline cache, falling back to server
  Future<DocumentSnapshot<Map<String, dynamic>>> getCachedDocument(
    String collection,
    String docId,
  ) async {
    try {
      // 1. Try reading from device local cache first (zero latency & works offline)
      return await _firestore
          .collection(collection)
          .doc(docId)
          .get(const GetOptions(source: Source.cache));
    } catch (_) {
      // 2. If not found in cache, fetch from server (which updates cache automatically)
      return await _firestore.collection(collection).doc(docId).get();
    }
  }

  /// Write data to Firestore with offline caching enabled.
  /// (Firestore automatically stores it in local SQLite/LevelDB and syncs when online)
  Future<void> saveDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      dev.log('Firestore write queued or error: $e', name: 'FirestoreCacheService');
    }
  }

  /// Real-time stream listening with cache persistence
  Stream<DocumentSnapshot<Map<String, dynamic>>> documentStream(
    String collection,
    String docId,
  ) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }
}
