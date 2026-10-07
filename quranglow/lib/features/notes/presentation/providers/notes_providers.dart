import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sync/sync_providers.dart';
import '../../data/repositories/notes_repository.dart';
import '../../domain/entities/quran_note.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final syncManager = ref.watch(syncManagerProvider);
  return NotesRepositoryImpl(syncManager: syncManager);
});

final notesListProvider = FutureProvider<List<QuranNote>>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  return await repo.getNotes();
});
