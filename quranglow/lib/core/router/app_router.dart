import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/user_name_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../providers/core_providers.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final localStorageService = ref.watch(localStorageServiceProvider);

  return GoRouter(
    initialLocation: localStorageService.isOnboarded() ? AppRoutes.home : AppRoutes.welcome,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const UserNameScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
