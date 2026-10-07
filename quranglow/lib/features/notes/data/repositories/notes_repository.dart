import '../../../core/firebase/auth/auth_service.dart';
import '../../../core/firebase/firestore/firestore_notes_service.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/sync/sync_operation.dart';
import '../../domain/entities/quran_note.dart';

abstract class NotesRepository {
  Future<List<QuranNote>> getNotes();
  Future<void> saveNote(QuranNote note);
  Future<void> deleteNote(String noteId);
}

class NotesRepositoryImpl implements NotesRepository {
  final LocalDatabase _localDb;
  final FirestoreNotesService _firestoreNotesService;
  final AuthService _authService;
  final SyncManager _syncManager;

  NotesRepositoryImpl({
    LocalDatabase? localDb,
    FirestoreNotesService? firestoreNotesService,
    AuthService? authService,
    required SyncManager syncManager,
  })  : _localDb = localDb ?? LocalDatabase.instance,
        _firestoreNotesService = firestoreNotesService ?? FirestoreNotesService(),
        _authService = authService ?? AuthService(),
        _syncManager = syncManager;

  @override
  Future<List<QuranNote>> getNotes() async {
    // 1. Check local DB first (offline first)
    final rawNotes = _localDb.getSetting('cached_notes');
    if (rawNotes is List) {
      return rawNotes
          .map((m) => QuranNote.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    }

    // 2. Fallback to Firestore if authenticated
    final uid = _authService.currentUid;
    if (uid != null) {
      try {
        final remote = await _firestoreNotesService.getAllNotes(uid);
        final notes = remote.map((m) => QuranNote.fromMap(m)).toList();
        await _localDb.setSetting('cached_notes', remote);
        return notes;
      } catch (_) {}
    }

    return [];
  }

  @override
  Future<void> saveNote(QuranNote note) async {
    // 1. Optimistic Local Save
    final currentList = await getNotes();
    final updatedList = List<QuranNote>.from(currentList)
      ..removeWhere((n) => n.id == note.id)
      ..add(note);

    await _localDb.setSetting(
      'cached_notes',
      updatedList.map((n) => n.toMap()).toList(),
    );

    // 2. Queue for Firebase Sync
    await _syncManager.enqueue(
      entityType: 'notes',
      entityId: note.id,
      type: SyncOperationType.create,
      payload: note.toMap(),
    );
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final currentList = await getNotes();
    final updatedList = List<QuranNote>.from(currentList)
      ..removeWhere((n) => n.id == noteId);

    await _localDb.setSetting(
      'cached_notes',
      updatedList.map((n) => n.toMap()).toList(),
    );

    await _syncManager.enqueue(
      entityType: 'notes',
      entityId: noteId,
      type: SyncOperationType.delete,
      payload: {'id': noteId},
    );
  }
}
