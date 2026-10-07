import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_collections.dart';

class FirestoreMemorizationService {
  final FirebaseFirestore _firestore;

  FirestoreMemorizationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid);
  }

  // ==================== Plans ====================
  CollectionReference<Map<String, dynamic>> _plansRef(String uid) {
    return _userRef(uid)
        .collection(FirestoreCollections.memorization)
        .doc('data')
        .collection('plans');
  }

  Future<List<Map<String, dynamic>>> getAllPlans(String uid) async {
    final snap = await _plansRef(uid).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<void> savePlan(String uid, Map<String, dynamic> plan) async {
    final id = plan['id']?.toString() ?? 'plan_${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(plan);
    payload['id'] = id;
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _plansRef(uid).doc(id).set(payload, SetOptions(merge: true));
  }

  Future<void> deletePlan(String uid, String planId) async {
    await _plansRef(uid).doc(planId).delete();
  }

  // ==================== Revision Sessions ====================
  CollectionReference<Map<String, dynamic>> _revisionRef(String uid) {
    return _userRef(uid).collection(FirestoreCollections.revisionSessions);
  }

  Future<void> saveRevisionSession(String uid, Map<String, dynamic> session) async {
    final id = session['id']?.toString() ?? 'rev_${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(session);
    payload['id'] = id;
    payload['createdAt'] = FieldValue.serverTimestamp();
    await _revisionRef(uid).doc(id).set(payload, SetOptions(merge: true));
  }
}
