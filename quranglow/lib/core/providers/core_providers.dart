import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';
import '../network/network_info.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../storage/cache_manager.dart';
import '../storage/firestore_cache_service.dart';

// 1. Firebase Service Provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// 2. Local Storage Provider (Overridden in main with instance)
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageServiceProvider must be initialized in main()');
});

// 3. Cache Manager Provider
final cacheManagerProvider = Provider<CacheManager>((ref) {
  throw UnimplementedError('cacheManagerProvider must be initialized in main()');
});

// 4. Firestore Cache Provider
final firestoreCacheServiceProvider = Provider<FirestoreCacheService>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return FirestoreCacheService(firebaseService: firebaseService);
});

// 5. Network Info Provider
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

// 6. Network Connectivity Stream Provider
final isConnectedProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});

// 7. Core ApiService Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
