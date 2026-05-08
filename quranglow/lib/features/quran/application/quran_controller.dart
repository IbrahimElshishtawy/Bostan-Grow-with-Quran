/// Main Quran state controller
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/api/quran_api_service.dart';
import 'package:quranglow/core/models/quran_models.dart';

class QuranState {
  const QuranState({
    required this.currentSurah,
    required this.currentAyah,
    required this.allSurahs,
    required this.isLoading,
    this.error,
  });

  final Surah? currentSurah;
  final Ayah? currentAyah;
  final List<Surah> allSurahs;
  final bool isLoading;
  final String? error;

  QuranState copyWith({
    Surah? currentSurah,
    Ayah? currentAyah,
    List<Surah>? allSurahs,
    bool? isLoading,
    String? error,
  }) {
    return QuranState(
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      allSurahs: allSurahs ?? this.allSurahs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QuranController extends StateNotifier<QuranState> {
  QuranController({required this.quranApiService})
      : super(
          const QuranState(
            currentSurah: null,
            currentAyah: null,
            allSurahs: [],
            isLoading: false,
          ),
        );

  final QuranApiService quranApiService;

  /// Initialize Quran data
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final surahs = await quranApiService.getAllSurahs();
      state = state.copyWith(
        allSurahs: surahs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load specific Surah
  Future<void> loadSurah(int surahNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final surah = await quranApiService.getSurah(surahNumber);
      state = state.copyWith(
        currentSurah: surah,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load Ayahs for current Surah
  Future<List<Ayah>> loadAyahs(int surahNumber) async {
    try {
      return await quranApiService.getAyahsForSurah(surahNumber);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Set current Ayah
  void setCurrentAyah(Ayah ayah) {
    state = state.copyWith(currentAyah: ayah);
  }

  /// Search Ayahs
  Future<List<Ayah>> searchAyahs(String keyword) async {
    try {
      return await quranApiService.searchAyahs(keyword);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
