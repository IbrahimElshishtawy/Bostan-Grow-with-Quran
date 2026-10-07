import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreKhatmahService {
  final FirebaseFirestore _firestore;

  FirestoreKhatmahService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _khatmahRef(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection(FirestoreCollections.khatmah);
  }

  Future<List<Map<String, dynamic>>> getAllKhatmah(String uid) async {
    final snap = await _khatmahRef(uid).orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Stream<List<Map<String, dynamic>>> streamKhatmah(String uid) {
    return _khatmahRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> saveKhatmah(String uid, Map<String, dynamic> khatmah) async {
    final id = khatmah['id']?.toString() ?? 'khatmah_${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(khatmah);
    payload['id'] = id;
    payload['updatedAt'] = FieldValue.serverTimestamp();
    if (!payload.containsKey('createdAt')) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await _khatmahRef(uid).doc(id).set(payload, SetOptions(merge: true));
  }

  Future<void> deleteKhatmah(String uid, String khatmahId) async {
    await _khatmahRef(uid).doc(khatmahId).delete();
  }
}
