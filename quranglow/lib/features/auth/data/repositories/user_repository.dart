import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> registerUser(String name);
  bool isOnboarded();
}

class UserRepositoryImpl implements UserRepository {
  final FirebaseService _firebaseService;
  final LocalStorageService _localStorageService;

  UserRepositoryImpl({
    required FirebaseService firebaseService,
    required LocalStorageService localStorageService,
  })  : _firebaseService = firebaseService,
        _localStorageService = localStorageService;

  @override
  bool isOnboarded() {
    return _localStorageService.isOnboarded() &&
        (_localStorageService.getUserName()?.isNotEmpty ?? false);
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    // 1. Check local device cache first for instant retrieval
    final cachedName = _localStorageService.getUserName();
    final cachedId = _localStorageService.getUserId();

    if (cachedName != null && cachedName.isNotEmpty && cachedId != null) {
      return UserProfile(
        id: cachedId,
        name: cachedName,
        createdAt: DateTime.now(),
      );
    }

    // 2. Fallback to Firestore cache/network
    try {
      final user = await _firebaseService.ensureAnonymousUser();
      if (user != null) {
        final doc = await _firebaseService.firestore
            .collection(AppConstants.firestoreUsersCollection)
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache))
            .catchError((_) {
          // If not in cache, fetch normally
          return _firebaseService.firestore
              .collection(AppConstants.firestoreUsersCollection)
              .doc(user.uid)
              .get();
        });

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final profile = UserProfile(
            id: user.uid,
            name: data['name'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          );

          // Update local cache
          await _localStorageService.setUserId(profile.id);
          await _localStorageService.setUserName(profile.name);
          await _localStorageService.setIsOnboarded(true);

          return profile;
        }
      }
    } catch (e) {
      dev.log('Error getting current user from Firestore: $e', name: 'UserRepository');
    }

    return null;
  }

  @override
  Future<UserProfile> registerUser(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('يرجى إدخال اسم صحيح');
    }

    // 1. Authenticate anonymously or generate a persistent local UID
    String userId = '';
    try {
      final user = await _firebaseService.ensureAnonymousUser();
      if (user != null) {
        userId = user.uid;
      }
    } catch (e) {
      dev.log('Anonymous sign in error, fallback to device timestamp id: $e', name: 'UserRepository');
    }

    if (userId.isEmpty) {
      userId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
    }

    final now = DateTime.now();
    final profile = UserProfile(
      id: userId,
      name: trimmedName,
      createdAt: now,
    );

    // 2. Save directly to Firestore (Firestore offline cache preserves this even if offline)
    try {
      await _firebaseService.firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .set({
        'name': trimmedName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      dev.log('Firestore write queued or error: $e', name: 'UserRepository');
    }

    // 3. Save to local device cache via SharedPreferences
    await _localStorageService.setUserId(userId);
    await _localStorageService.setUserName(trimmedName);
    await _localStorageService.setIsOnboarded(true);

    return profile;
  }
}
