import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_database.dart';
import '../../domain/entities/memorization_plan.dart';

class MemorizationNotifier extends StateNotifier<List<MemorizationPlan>> {
  final LocalDatabase _localDb;

  MemorizationNotifier(this._localDb) : super([]) {
    loadPlans();
  }

  void loadPlans() {
    final list = _localDb.getAllMemorizationPlans();
    state = list.map((m) => MemorizationPlan.fromMap(m)).toList();
  }

  Future<void> createPlan({
    required int surahNumber,
    required String surahName,
    required int startAyah,
    required int endAyah,
    required int targetDays,
  }) async {
    final now = DateTime.now();
    final plan = MemorizationPlan(
      id: 'mem_${now.millisecondsSinceEpoch}',
      surahNumber: surahNumber,
      surahName: surahName,
      startAyah: startAyah,
      endAyah: endAyah,
      targetDays: targetDays,
      createdAt: now,
      nextRevisionDate: now.add(const Duration(days: 1)),
    );

    await _localDb.saveMemorizationPlan(plan.toMap());
    loadPlans();
  }

  Future<void> markAyahMemorized(String planId, int ayahNumber) async {
    final index = state.indexWhere((p) => p.id == planId);
    if (index != -1) {
      final plan = state[index];
      final memorized = List<int>.from(plan.memorizedAyahs);
      if (!memorized.contains(ayahNumber)) {
        memorized.add(ayahNumber);
        final updated = plan.copyWith(memorizedAyahs: memorized);
        await _localDb.saveMemorizationPlan(updated.toMap());
        loadPlans();
      }
    }
  }

  Future<void> recordRevisionResult({
    required String planId,
    required bool isSuccess,
    required int testedAyah,
  }) async {
    final index = state.indexWhere((p) => p.id == planId);
    if (index != -1) {
      final plan = state[index];
      final weak = List<int>.from(plan.weakAyahs);

      if (!isSuccess && !weak.contains(testedAyah)) {
        weak.add(testedAyah);
      } else if (isSuccess && weak.contains(testedAyah)) {
        weak.remove(testedAyah);
      }

      final nextDate = DateTime.now().add(Duration(days: isSuccess ? 3 : 1));
      final updated = plan.copyWith(
        weakAyahs: weak,
        nextRevisionDate: nextDate,
      );
      await _localDb.saveMemorizationPlan(updated.toMap());
      loadPlans();
    }
  }
}

final memorizationNotifierProvider =
    StateNotifierProvider<MemorizationNotifier, List<MemorizationPlan>>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  return MemorizationNotifier(localDb);
});
