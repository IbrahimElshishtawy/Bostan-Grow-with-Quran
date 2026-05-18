import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive/hive.dart';
import 'package:quranglow/core/model/reminder/reminder.dart';
import 'package:quranglow/core/service/sync/firebase_guard.dart';
import 'package:quranglow/core/utils/logger.dart';

class RemindersService {
  FirebaseFirestore? get _firestore =>
      FirebaseGuard.isReady ? FirebaseFirestore.instance : null;

  FirebaseAuth? get _auth => FirebaseGuard.isReady ? FirebaseAuth.instance : null;

  CollectionReference<Map<String, dynamic>>? get _remindersCol {
    final user = _auth?.currentUser;
    final firestore = _firestore;
    if (user == null || firestore == null) return null;
    return firestore.collection('users').doc(user.uid).collection('reminders');
  }

  Future<void> saveReminder(Reminder reminder) async {
    // 1. Save locally to Hive box first (guarantees offline/debug compatibility)
    try {
      final box = await Hive.openBox<Map>('local_reminders');
      await box.put(reminder.id.toString(), reminder.toMap());
    } catch (e, st) {
      L.e('RemindersService', 'Failed to save reminder locally to Hive', st);
    }

    // 2. Save to Firestore if available
    final col = _remindersCol;
    if (col == null) return;
    try {
      await col.doc(reminder.id.toString()).set({
        ...reminder.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      L.d('RemindersService', 'Reminder saved to Firestore');
    } catch (e, st) {
      L.e('RemindersService', 'Failed to save reminder to Firestore', st);
      if (FirebaseGuard.isReady) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Failed to save reminder to Firestore',
        );
      }
    }
  }

  Future<void> deleteReminder(int id) async {
    // 1. Delete locally from Hive
    try {
      final box = await Hive.openBox<Map>('local_reminders');
      await box.delete(id.toString());
    } catch (e, st) {
      L.e('RemindersService', 'Failed to delete reminder locally from Hive', st);
    }

    // 2. Delete from Firestore if available
    final col = _remindersCol;
    if (col == null) return;
    try {
      await col.doc(id.toString()).delete();
      L.d('RemindersService', 'Reminder deleted from Firestore');
    } catch (e, st) {
      L.e('RemindersService', 'Failed to delete reminder from Firestore', st);
    }
  }

  Future<List<Reminder>> fetchReminders() async {
    // 1. Always load from Hive local box first
    final List<Reminder> localReminders = [];
    try {
      final box = await Hive.openBox<Map>('local_reminders');
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(val);
          localReminders.add(Reminder.fromMap(map));
        }
      }
    } catch (e, st) {
      L.e('RemindersService', 'Failed to fetch local reminders from Hive', st);
    }

    // 2. Try Firestore if available
    final col = _remindersCol;
    if (col == null) {
      // Return local cache if Firebase is not signed in/ready
      return localReminders;
    }

    try {
      final snapshot = await col.get();
      final List<Reminder> remoteReminders = snapshot.docs
          .map((doc) => Reminder.fromMap(doc.data()))
          .toList();

      // Sync Firestore reminders to local Hive cache
      final box = await Hive.openBox<Map>('local_reminders');
      for (final r in remoteReminders) {
        await box.put(r.id.toString(), r.toMap());
      }

      return remoteReminders.isNotEmpty ? remoteReminders : localReminders;
    } catch (e, st) {
      L.e('RemindersService', 'Failed to fetch reminders from Firestore, using local fallback', st);
      return localReminders;
    }
  }
}
