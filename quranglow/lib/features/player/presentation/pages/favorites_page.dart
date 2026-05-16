import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/providers/favorites_controller.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'المفضلات الصوتية',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E3C40), const Color(0xFF121212)]
                : [const Color(0xFFFDFCF0), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 80,
                        color: cs.onSurface.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد سور مفضلة بعد',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 18,
                          fontFamily: 'Tajawal',
                        ),
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
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.teal,
                          ),
                        ),
                        title: Text(
                          fav.surahName,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        subtitle: Text(
                          fav.reciterName,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => ref
                              .read(favoritesControllerProvider.notifier)
                              .toggleFavorite(
                                editionId: fav.editionId,
                                chapter: fav.chapter,
                                surahName: fav.surahName,
                                reciterName: fav.reciterName,
                              ),
                        ),
                        onTap: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .changeEdition(fav.editionId);
                          ref
                              .read(playerControllerProvider.notifier)
                              .changeChapter(fav.chapter);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
