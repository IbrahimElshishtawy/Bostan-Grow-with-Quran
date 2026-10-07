import 'package:flutter_test/flutter_test.dart';
import 'package:quranglow/core/firebase/auth/auth_state.dart';
import 'package:quranglow/core/firebase/firestore/firestore_collections.dart';

void main() {
  group('Firebase Architecture Tests', () {
    test('AppAuthState reflects correct states and permissions', () {
      final initial = AppAuthState.initial();
      expect(initial.status, equals(AuthStatus.initial));
      expect(initial.isSignedIn, isFalse);

      final unauth = AppAuthState.unauthenticated();
      expect(unauth.status, equals(AuthStatus.unauthenticated));
      expect(unauth.isSignedIn, isFalse);

      final err = AppAuthState.error('Network timeout');
      expect(err.status, equals(AuthStatus.error));
      expect(err.errorMessage, equals('Network timeout'));
    });

    test('FirestoreCollections paths conform to master schema specification', () {
      expect(FirestoreCollections.users, equals('users'));
      expect(FirestoreCollections.preferences, equals('preferences'));
      expect(FirestoreCollections.devices, equals('devices'));
      expect(FirestoreCollections.reading, equals('reading'));
      expect(FirestoreCollections.readingSessions, equals('readingSessions'));
      expect(FirestoreCollections.bookmarks, equals('bookmarks'));
      expect(FirestoreCollections.notes, equals('notes'));
      expect(FirestoreCollections.memorization, equals('memorization'));
      expect(FirestoreCollections.khatmah, equals('khatmah'));
      expect(FirestoreCollections.goals, equals('goals'));
      expect(FirestoreCollections.dailyActivity, equals('dailyActivity'));
      expect(FirestoreCollections.statistics, equals('statistics'));
      expect(FirestoreCollections.achievements, equals('achievements'));
      expect(FirestoreCollections.events, equals('events'));
      expect(FirestoreCollections.notifications, equals('notifications'));
    });
  });
}
