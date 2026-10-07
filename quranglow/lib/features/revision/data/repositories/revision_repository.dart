import '../../../core/storage/local_database.dart';
import '../../memorization/domain/services/revision_engine.dart';
import '../domain/entities/revision_item.dart';

abstract class RevisionRepository {
  Future<List<RevisionItem>> getDueRevisions();
  Future<void> submitRevisionRating({
    required String itemId,
    required RevisionRating rating,
  });
}

class RevisionRepositoryImpl implements RevisionRepository {
  final LocalDatabase _localDb;

  RevisionRepositoryImpl({LocalDatabase? localDb})
      : _localDb = localDb ?? LocalDatabase.instance;

  @override
  Future<List<RevisionItem>> getDueRevisions() async {
    final rawList = _localDb.getSetting('cached_revision_items');
    if (rawList is List) {
      return rawList
          .map((m) => RevisionItem.fromMap(Map<String, dynamic>.from(m as Map)))
          .where((item) => item.isDueToday)
          .toList();
    }
    return [];
  }

  @override
  Future<void> submitRevisionRating({
    required String itemId,
    required RevisionRating rating,
  }) async {
    final rawList = _localDb.getSetting('cached_revision_items');
    final allItems = <RevisionItem>[];

    if (rawList is List) {
      allItems.addAll(
        rawList.map((m) => RevisionItem.fromMap(Map<String, dynamic>.from(m as Map))),
      );
    }

    final index = allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final current = allItems[index];
      final isSuccess = rating == RevisionRating.good || rating == RevisionRating.easy;
      final nextDate = RevisionEngine.calculateNextRevisionDate(
        isCorrect: isSuccess,
        currentStreak: current.reviewCount,
      );

      final updated = RevisionItem(
        id: current.id,
        surahId: current.surahId,
        startAyah: current.startAyah,
        endAyah: current.endAyah,
        nextReviewAt: nextDate,
        reviewCount: isSuccess ? current.reviewCount + 1 : 0,
        lastRating: rating,
      );

      allItems[index] = updated;
      await _localDb.setSetting('cached_revision_items', allItems.map((i) => i.toMap()).toList());
    }
  }
}
