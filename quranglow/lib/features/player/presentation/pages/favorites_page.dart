import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/providers/favorites_controller.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('المفضلات الصوتية', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text(
                    'لا يوجد سور مفضلة بعد',
                    style: TextStyle(color: Colors.white38, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final fav = favorites[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.tealAccent),
                    ),
                    title: Text(
                      fav.surahName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      fav.reciterName,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => ref.read(favoritesControllerProvider.notifier).toggleFavorite(
                            editionId: fav.editionId,
                            chapter: fav.chapter,
                            surahName: fav.surahName,
                            reciterName: fav.reciterName,
                          ),
                    ),
                    onTap: () {
                      // Navigate to player and start playback
                      ref.read(playerControllerProvider.notifier).changeEdition(fav.editionId);
                      ref.read(playerControllerProvider.notifier).changeChapter(fav.chapter);
                      Navigator.pop(context); // Go back if this was opened from drawer/settings
                    },
                  ),
                );
              },
            ),
    );
  }
}
