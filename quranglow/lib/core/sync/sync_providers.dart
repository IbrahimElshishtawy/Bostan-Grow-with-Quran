import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_manager.dart';
import 'sync_metadata.dart';

final syncManagerProvider = ChangeNotifierProvider<SyncManager>((ref) {
  return SyncManager();
});

final syncMetadataProvider = Provider<SyncMetadata>((ref) {
  final manager = ref.watch(syncManagerProvider);
  return manager.metadata;
});
