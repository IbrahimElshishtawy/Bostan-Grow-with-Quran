import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreNotesService {
  final FirebaseFirestore _firestore;

  FirestoreNotesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesRef(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.notes);
  }

  Future<List<Map<String, dynamic>>> getAllNotes(String uid) async {
    final snap = await _notesRef(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Stream<List<Map<String, dynamic>>> streamNotes(String uid) {
    return _notesRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<void> saveNote(String uid, Map<String, dynamic> note) async {
    final id = note['id']?.toString() ??
        'note_${note['surahId']}_${note['ayahId']}_${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(note);
    payload['id'] = id;
    payload['updatedAt'] = FieldValue.serverTimestamp();
    if (!payload.containsKey('createdAt')) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await _notesRef(uid).doc(id).set(payload, SetOptions(merge: true));
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _notesRef(uid).doc(noteId).delete();
  }
}
