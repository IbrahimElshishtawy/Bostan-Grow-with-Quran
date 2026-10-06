import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/user_controller.dart';
import '../../features/auth/presentation/screens/user_name_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);

  return GoRouter(
    initialLocation: localStorageService.isOnboarded() ? '/home' : '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const UserNameScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
