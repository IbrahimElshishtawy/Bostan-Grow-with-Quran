import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/quran_local_data_source.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/quran_page.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';

final quranLocalDataSourceProvider = Provider<QuranLocalDataSource>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  return QuranLocalDataSourceImpl(localDb);
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  final localDataSource = ref.watch(quranLocalDataSourceProvider);
  return QuranRepositoryImpl(localDataSource);
});

final surahsListProvider = FutureProvider<List<Surah>>((ref) async {
  final repo = ref.watch(quranRepositoryProvider);
  final result = await repo.getSurahs();
  return result.fold(
    onSuccess: (surahs) => surahs,
    onFailure: (failure) => throw failure,
  );
});

final mushafPageProvider = FutureProvider.family<QuranPage, int>((ref, pageNumber) async {
  final repo = ref.watch(quranRepositoryProvider);
  final result = await repo.getPage(pageNumber);
  return result.fold(
    onSuccess: (page) => page,
    onFailure: (failure) => throw failure,
  );
});

class MushafState {
  final int currentPage;
  final double fontSize;
  final bool isNightMode;
  final Ayah? selectedAyah;
  final int lastSavedPage;

  const MushafState({
    this.currentPage = 1,
    this.fontSize = 24.0,
    this.isNightMode = false,
    this.selectedAyah,
    this.lastSavedPage = 1,
  });

  MushafState copyWith({
    int? currentPage,
    double? fontSize,
    bool? isNightMode,
    Ayah? selectedAyah,
    bool clearSelectedAyah = false,
    int? lastSavedPage,
  }) {
    return MushafState(
      currentPage: currentPage ?? this.currentPage,
      fontSize: fontSize ?? this.fontSize,
      isNightMode: isNightMode ?? this.isNightMode,
      selectedAyah: clearSelectedAyah ? null : (selectedAyah ?? this.selectedAyah),
      lastSavedPage: lastSavedPage ?? this.lastSavedPage,
    );
  }
}

class MushafController extends StateNotifier<MushafState> {
  final QuranRepository _repository;

  MushafController(this._repository) : super(const MushafState()) {
    _loadLastPosition();
  }

  void _loadLastPosition() {
    final pos = _repository.getLastReadingPosition();
    if (pos != null && pos['pageNumber'] != null) {
      final page = pos['pageNumber'] as int;
      state = state.copyWith(
        currentPage: page,
        lastSavedPage: page,
      );
    }
  }

  void goToPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) return;
    state = state.copyWith(currentPage: pageNumber, clearSelectedAyah: true);
    _persistPosition(pageNumber);
  }

  void selectAyah(Ayah? ayah) {
    if (ayah == null) {
      state = state.copyWith(clearSelectedAyah: true);
    } else {
      state = state.copyWith(selectedAyah: ayah);
    }
  }

  void toggleNightMode() {
    state = state.copyWith(isNightMode: !state.isNightMode);
  }

  void setFontSize(double size) {
    if (size >= 18.0 && size <= 36.0) {
      state = state.copyWith(fontSize: size);
    }
  }

  Future<bool> toggleBookmark(Ayah ayah) async {
    final result = await _repository.toggleBookmark(ayah);
    return result.fold(
      onSuccess: (status) => status,
      onFailure: (_) => false,
    );
  }

  void _persistPosition(int pageNumber) {
    _repository.saveReadingPosition(
      pageNumber: pageNumber,
      surahNumber: 1,
      ayahNumber: 1,
    );
  }
}

final mushafControllerProvider =
    StateNotifierProvider<MushafController, MushafState>((ref) {
  final repo = ref.watch(quranRepositoryProvider);
  return MushafController(repo);
});
