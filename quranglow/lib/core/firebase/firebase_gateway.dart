import 'auth/auth_service.dart';
import 'firestore/firestore_user_service.dart';
import 'firestore/firestore_reading_service.dart';
import 'firestore/firestore_bookmarks_service.dart';
import 'firestore/firestore_notes_service.dart';
import 'firestore/firestore_memorization_service.dart';
import 'firestore/firestore_khatmah_service.dart';
import 'firestore/firestore_devices_service.dart';
import 'analytics/analytics_service.dart';
import 'messaging/messaging_service.dart';
import 'app_check/app_check_service.dart';

class FirebaseGateway {
  static final FirebaseGateway _instance = FirebaseGateway._internal();
  factory FirebaseGateway() => _instance;
  FirebaseGateway._internal();

  final AuthService auth = AuthService();
  final FirestoreUserService user = FirestoreUserService();
  final FirestoreReadingService reading = FirestoreReadingService();
  final FirestoreBookmarksService bookmarks = FirestoreBookmarksService();
  final FirestoreNotesService notes = FirestoreNotesService();
  final FirestoreMemorizationService memorization = FirestoreMemorizationService();
  final FirestoreKhatmahService khatmah = FirestoreKhatmahService();
  final FirestoreDevicesService devices = FirestoreDevicesService();
  final AnalyticsService analytics = AnalyticsService();
  final MessagingService messaging = MessagingService();

  static Future<void> initializeAppCheck() async {
    await AppCheckService.initialize();
  }
}
