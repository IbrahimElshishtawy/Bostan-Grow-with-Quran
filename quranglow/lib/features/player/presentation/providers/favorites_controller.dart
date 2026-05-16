import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quranglow/core/model/audio/favorite_audio.dart';

final favoritesControllerProvider = StateNotifierProvider<FavoritesController, List<FavoriteAudio>>((ref) {
  return FavoritesController();
});

class FavoritesController extends StateNotifier<List<FavoriteAudio>> {
  FavoritesController() : super([]) {
    _init();
  }

  static const _boxName = 'favorite_audio_box';

  Future<void> _init() async {
    final box = await Hive.openBox<Map>(_boxName);
    state = box.values.map((e) => FavoriteAudio.fromMap(e)).toList();
  }

  Future<void> toggleFavorite({
    required String editionId,
    required int chapter,
    required String surahName,
    required String reciterName,
  }) async {
    final box = await Hive.openBox<Map>(_boxName);
    final id = '${editionId}_$chapter';
    
    if (box.containsKey(id)) {
      await box.delete(id);
    } else {
      final fav = FavoriteAudio(
        id: id,
        editionId: editionId,
        chapter: chapter,
        surahName: surahName,
        reciterName: reciterName,
        addedAt: DateTime.now(),
      );
      await box.put(id, fav.toMap());
    }
    state = box.values.map((e) => FavoriteAudio.fromMap(e)).toList();
  }

  bool isFavorite(String editionId, int chapter) {
    final id = '${editionId}_$chapter';
    return state.any((e) => e.id == id);
  }
}
