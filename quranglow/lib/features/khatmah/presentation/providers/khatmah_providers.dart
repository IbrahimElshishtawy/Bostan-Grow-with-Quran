import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/local_database.dart';
import '../../domain/entities/khatmah_plan.dart';

class KhatmahNotifier extends StateNotifier<List<KhatmahPlan>> {
  final LocalDatabase _localDb;

  KhatmahNotifier(this._localDb) : super([]) {
    loadPlans();
  }

  void loadPlans() {
    final list = _localDb.getAllKhatmahPlans();
    state = list.map((m) => KhatmahPlan.fromMap(m)).toList();
  }

  Future<void> createPlan({
    required String title,
    required int durationDays,
    int startPage = 1,
  }) async {
    final now = DateTime.now();
    final plan = KhatmahPlan(
      id: 'khatmah_${now.millisecondsSinceEpoch}',
      title: title,
      durationDays: durationDays,
      startPage: startPage,
      currentPage: startPage,
      startDate: now,
      targetEndDate: now.add(Duration(days: durationDays)),
    );

    await _localDb.saveKhatmahPlan(plan.toMap());
    loadPlans();
  }

  Future<void> updateCurrentPage(String id, int newPage) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(
        currentPage: newPage,
        isCompleted: newPage >= 604,
      );
      await _localDb.saveKhatmahPlan(updated.toMap());
      loadPlans();
    }
  }

  Future<void> deletePlan(String id) async {
    await _localDb.deleteKhatmahPlan(id);
    loadPlans();
  }
}

final khatmahNotifierProvider =
    StateNotifierProvider<KhatmahNotifier, List<KhatmahPlan>>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  return KhatmahNotifier(localDb);
});

final activeKhatmahProvider = Provider<KhatmahPlan?>((ref) {
  final plans = ref.watch(khatmahNotifierProvider);
  final uncompleted = plans.where((p) => !p.isCompleted).toList();
  return uncompleted.isNotEmpty ? uncompleted.first : null;
});
