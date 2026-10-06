import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user_profile.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);
  return UserRepositoryImpl(
    firebaseService: firebaseService,
    localStorageService: localStorageService,
  );
});

// State
class UserState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isOnboarded => user != null && user!.name.isNotEmpty;

  UserState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Controller
class UserController extends StateNotifier<UserState> {
  final UserRepository _repository;

  UserController(this._repository) : super(const UserState()) {
    loadUser();
  }

  Future<void> loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> registerUserName(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.registerUser(name);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }
}

final userControllerProvider = StateNotifierProvider<UserController, UserState>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return UserController(repo);
});
