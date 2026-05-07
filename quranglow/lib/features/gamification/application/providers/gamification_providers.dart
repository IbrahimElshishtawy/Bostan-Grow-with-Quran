/// Gamification Riverpod providers for state management

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quranglow/features/gamification/application/gamification_controller.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

// Repository provider
final gameificationRepositoryProvider = Provider((ref) {
  return GameificationRepository(
    firestore: FirebaseFirestore.instance,
  );
});

// Auth provider
final authProvider = Provider((ref) {
  return FirebaseAuth.instance;
});

// Current user provider
final currentUserProvider = Provider((ref) {
  return ref.watch(authProvider).currentUser;
});

// Gamification controller provider
final gamificationControllerProvider =
    StateNotifierProvider<GameificationController, AsyncValue<GameState>>((ref) {
  final repository = ref.watch(gameificationRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return GameificationController(
      repository: repository,
      userId: '',
    )..initialize();
  }

  return GameificationController(
    repository: repository,
    userId: user.uid,
  )..initialize();
});

// User profile provider
final userProfileProvider = FutureProvider<UserGameProfile>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.getUserProfile(user.uid);
});

// Levels provider
final levelsProvider = FutureProvider<List<GameLevel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.getLevels(user.uid);
});

// Current level provider
final currentLevelProvider = FutureProvider<GameLevel?>((ref) async {
  final gameState = await ref.watch(gamificationControllerProvider.future);
  return gameState.currentLevel;
});

// User stats provider
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw Exception('User not authenticated');

  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.getUserStats(user.uid);
});

// Stream providers for real-time updates
final userProfileStreamProvider =
    StreamProvider<UserGameProfile>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.streamUserProfile(user.uid);
});

final levelsStreamProvider = StreamProvider<List<GameLevel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.streamLevels(user.uid);
});

// Due review levels provider
final dueReviewLevelsProvider = FutureProvider<List<GameLevel>>((ref) async {
  final gameState = await ref.watch(gamificationControllerProvider.future);
  return gameState.dueReviewLevels;
});

// Overall progress provider
final overallProgressProvider = FutureProvider<double>((ref) async {
  final gameState = await ref.watch(gamificationControllerProvider.future);
  return gameState.overallProgress;
});

// Completed levels count provider
final completedLevelsCountProvider = FutureProvider<int>((ref) async {
  final gameState = await ref.watch(gamificationControllerProvider.future);
  return gameState.completedLevels;
});

// Total levels count provider
final totalLevelsCountProvider = FutureProvider<int>((ref) async {
  final gameState = await ref.watch(gamificationControllerProvider.future);
  return gameState.totalLevels;
});
