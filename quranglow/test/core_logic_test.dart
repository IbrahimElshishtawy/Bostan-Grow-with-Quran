import 'package:flutter_test/flutter_test.dart';
import 'package:quranglow/core/error/failures.dart';
import 'package:quranglow/core/responsive/breakpoints.dart';
import 'package:quranglow/core/result/result.dart';
import 'package:quranglow/core/sync/sync_conflict_resolver.dart';
import 'package:quranglow/core/sync/sync_operation.dart';
import 'package:quranglow/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:quranglow/features/memorization/domain/services/revision_engine.dart';
import 'package:quranglow/features/search/domain/services/quran_search_engine.dart';

void main() {
  group('Result Type Tests', () {
    test('Success returns correct data and predicates', () {
      final Result<int> res = Result.success(42);
      expect(res.isSuccess, isTrue);
      expect(res.isFailure, isFalse);
      expect(res.dataOrNull, equals(42));
      expect(res.failureOrNull, isNull);

      final val = res.fold(
        onSuccess: (v) => 'Got $v',
        onFailure: (f) => 'Failed',
      );
      expect(val, equals('Got 42'));
    });

    test('Failure returns correct error and predicates', () {
      const Failure failure = CacheFailure('Disk error');
      final Result<int> res = Result.failure(failure);
      expect(res.isSuccess, isFalse);
      expect(res.isFailure, isTrue);
      expect(res.dataOrNull, isNull);
      expect(res.failureOrNull?.message, equals('Disk error'));
    });
  });

  group('KhatmahPlan Calculations', () {
    test('Calculates remaining pages, target and percentage accurately', () {
      final plan = KhatmahPlan(
        id: 'test_khatmah',
        title: 'Ramadan Khatmah',
        durationDays: 30,
        startPage: 1,
        currentPage: 61,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        targetEndDate: DateTime.now().add(const Duration(days: 27)),
      );

      expect(plan.totalPages, equals(604));
      expect(plan.remainingPages, equals(543));
      expect(plan.progressPercentage, greaterThan(0.09));
      expect(plan.requiredDailyPages, greaterThanOrEqualTo(20));
    });
  });

  group('RevisionEngine Spaced Repetition Tests', () {
    test('Calculate next revision date with streak progression', () {
      final dateStreak0 = RevisionEngine.calculateNextRevisionDate(
        isCorrect: true,
        currentStreak: 0,
      );
      final diffStreak0 = dateStreak0.difference(DateTime.now()).inDays;
      expect(diffStreak0, inInclusiveRange(0, 1));

      final dateStreak2 = RevisionEngine.calculateNextRevisionDate(
        isCorrect: true,
        currentStreak: 2,
      );
      final diffStreak2 = dateStreak2.difference(DateTime.now()).inDays;
      expect(diffStreak2, inInclusiveRange(6, 7));

      final dateFail = RevisionEngine.calculateNextRevisionDate(
        isCorrect: false,
        currentStreak: 5,
      );
      final diffFail = dateFail.difference(DateTime.now()).inDays;
      expect(diffFail, inInclusiveRange(0, 1));
    });

    test('Generates test questions with 1 correct answer and distractors', () {
      final question = RevisionEngine.generateNextAyahQuestion(
        surahNumber: 1,
        startAyah: 1,
        endAyah: 7,
      );

      expect(question, isNotNull);
      expect(question.options.length, equals(4));
      expect(question.options.contains(question.correctNextAyahText), isTrue);
    });
  });

  group('QuranSearchEngine Tashkeel Normalization', () {
    test('Normalizes Arabic letters and removes diacritics', () {
      const raw = 'إِنَّ الَّذِينَ آمَنُواْ';
      final clean = QuranSearchEngine.normalizeArabic(raw);
      expect(clean.contains('ان الذين امنوا'), isTrue);
    });
  });

  group('SyncEngine Unit Tests', () {
    test('SyncOperation serializes and deserializes correctly', () {
      final op = SyncOperation(
        id: 'op_1',
        entityType: 'bookmark',
        type: SyncOperationType.create,
        payload: {'surah': 2, 'ayah': 255},
        createdAt: DateTime(2026, 10, 7),
      );

      final map = op.toMap();
      expect(map['id'], equals('op_1'));
      expect(map['entityType'], equals('bookmark'));
      expect(map['type'], equals('create'));

      final restored = SyncOperation.fromMap(map);
      expect(restored.id, equals('op_1'));
      expect(restored.type, equals(SyncOperationType.create));
      expect(restored.payload['ayah'], equals(255));
    });

    test('SyncConflictResolver resolves using Last-Write-Wins timestamps', () {
      const resolver = SyncConflictResolver();
      final local = {
        'id': 'plan_1',
        'currentPage': 10,
        'updatedAt': '2026-10-07T12:00:00.000Z',
      };
      final remoteNewer = {
        'id': 'plan_1',
        'currentPage': 20,
        'updatedAt': '2026-10-07T14:00:00.000Z',
      };

      final result1 = resolver.resolve(localData: local, remoteData: remoteNewer);
      expect(result1['currentPage'], equals(20));

      final remoteOlder = {
        'id': 'plan_1',
        'currentPage': 5,
        'updatedAt': '2026-10-07T10:00:00.000Z',
      };
      final result2 = resolver.resolve(localData: local, remoteData: remoteOlder);
      expect(result2['currentPage'], equals(10));
    });
  });

  group('AppBreakpoints Specifications', () {
    test('Breakpoint constants match material 3 design standards', () {
      expect(AppBreakpoints.compactMaxWidth, equals(599.0));
      expect(AppBreakpoints.mediumMaxWidth, equals(839.0));
      expect(AppBreakpoints.expandedMinWidth, equals(840.0));
    });
  });
}
