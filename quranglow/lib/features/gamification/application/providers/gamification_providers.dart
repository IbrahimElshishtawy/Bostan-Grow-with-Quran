/// Gamification Riverpod providers for local offline-first state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/gamification/application/gamification_controller.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

// Repository provider
final gameificationRepositoryProvider = Provider((ref) {
  return GameificationRepository(
    storage: ref.watch(storageProvider),
  );
});

// Primary local user ID provider (no auth required for offline operation)
final currentUserIdProvider = Provider<String>((ref) {
  return 'local_user_quran_glow';
});

// Gamification controller provider
final gamificationControllerProvider =
    StateNotifierProvider<GameificationController, AsyncValue<GameState>>((ref) {
  final repository = ref.watch(gameificationRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return GameificationController(
    repository: repository,
    userId: userId,
  )..initialize();
});

// User profile provider
final userProfileProvider = FutureProvider<UserGameProfile>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.getUserProfile(userId);
});

// Levels provider
final levelsProvider = FutureProvider<List<GameLevel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.getLevels(userId);
});

// Current level provider
final currentLevelProvider = FutureProvider<GameLevel?>((ref) async {
  final gameStateAsync = ref.watch(gamificationControllerProvider);
  return gameStateAsync.maybeWhen(
    data: (gameState) => gameState.currentLevel,
    orElse: () => null,
  );
});

// User stats provider
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.getUserStats(userId);
});

// Stream providers for real-time updates
final userProfileStreamProvider =
    StreamProvider<UserGameProfile>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.streamUserProfile(userId);
});

final levelsStreamProvider = StreamProvider<List<GameLevel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(gameificationRepositoryProvider);
  return repository.streamLevels(userId);
});

// Due review levels provider
final dueReviewLevelsProvider = FutureProvider<List<GameLevel>>((ref) async {
  final gameStateAsync = ref.watch(gamificationControllerProvider);
  return gameStateAsync.maybeWhen(
    data: (gameState) => gameState.dueReviewLevels,
    orElse: () => [],
  );
});

// Overall progress provider
final overallProgressProvider = FutureProvider<double>((ref) async {
  final gameStateAsync = ref.watch(gamificationControllerProvider);
  return gameStateAsync.maybeWhen(
    data: (gameState) => gameState.overallProgress,
    orElse: () => 0.0,
  );
});

// Completed levels count provider
final completedLevelsCountProvider = FutureProvider<int>((ref) async {
  final gameStateAsync = ref.watch(gamificationControllerProvider);
  return gameStateAsync.maybeWhen(
    data: (gameState) => gameState.completedLevels,
    orElse: () => 0,
  );
});

// Total levels count provider
final totalLevelsCountProvider = FutureProvider<int>((ref) async {
  final gameStateAsync = ref.watch(gamificationControllerProvider);
  return gameStateAsync.maybeWhen(
    data: (gameState) => gameState.totalLevels,
    orElse: () => 0,
  );
});
