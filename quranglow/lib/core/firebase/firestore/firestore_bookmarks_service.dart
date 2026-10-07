import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreBookmarksService {
  final FirebaseFirestore _firestore;

  FirestoreBookmarksService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _bookmarksRef(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.bookmarks);
  }

  Future<List<Map<String, dynamic>>> getAllBookmarks(String uid) async {
    final snap = await _bookmarksRef(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Map<String, dynamic>>> streamBookmarks(String uid) {
    return _bookmarksRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<void> saveBookmark(String uid, Map<String, dynamic> bookmark) async {
    final id = bookmark['id']?.toString() ??
        'bm_${bookmark['surahId']}_${bookmark['ayahId']}';
    final payload = Map<String, dynamic>.from(bookmark);
    payload['id'] = id;
    payload['updatedAt'] = FieldValue.serverTimestamp();
    if (!payload.containsKey('createdAt')) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await _bookmarksRef(uid).doc(id).set(payload, SetOptions(merge: true));
  }

  Future<void> deleteBookmark(String uid, String bookmarkId) async {
    await _bookmarksRef(uid).doc(bookmarkId).delete();
  }
}
