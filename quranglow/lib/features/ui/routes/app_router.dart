// lib/features/ui/routes/router.dart
// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/service/quran/quran_service.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/about/presentation/pages/about_page.dart';
import 'package:quranglow/features/ayah/presentation/pages/ayah_detail_page.dart';
import 'package:quranglow/features/azkar/presentation/pages/azkar_tasbih_page.dart';
import 'package:quranglow/features/bookmarks/presentation/pages/bookmarks_page.dart';
import 'package:quranglow/features/downloads/presentation/pages/download_detail_page.dart'
    as ddp;
import 'package:quranglow/features/downloads/presentation/pages/downloads_library_page.dart';
import 'package:quranglow/features/downloads/presentation/pages/downloads_page.dart'
    as dlp;
import 'package:quranglow/features/goals/presentation/pages/goals_page.dart';
import 'package:quranglow/features/home/presentation/pages/home_page.dart';
import 'package:quranglow/features/mushaf/presentation/pages/mushaf_page.dart';
import 'package:quranglow/features/mushaf/presentation/pages/paged_mushaf.dart';
import 'package:quranglow/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:quranglow/features/player/presentation/pages/player_page.dart';
import 'package:quranglow/features/qibla/presentation/pages/qibla_page.dart';
import 'package:quranglow/features/search/presentation/pages/search_page.dart';
import 'package:quranglow/features/settings/presentation/pages/settings_page.dart';
import 'package:quranglow/features/splash/presentation/pages/splash_screen.dart';
import 'package:quranglow/features/stats/presentation/pages/stats_page.dart';
import 'package:quranglow/features/surah/presentation/pages/surah_list_page.dart';
import 'package:quranglow/features/tafsir/presentation/pages/tafsir_explorer_page.dart';
import 'package:quranglow/features/tafsir/presentation/pages/tafsir_reader_page.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_args.dart';
import 'package:quranglow/features/gamification/presentation/pages/modern_home_screen.dart';
import 'app_routes.dart';

final quranServiceProvider = Provider<QuranService>(
  (ref) => throw UnimplementedError(
    'Override quranServiceProvider in ProviderScope',
  ),
);

class MushafArgs {
  const MushafArgs({
    this.initialAyah,
    this.chapter = 1,
    this.editionId = 'quran-uthmani',
  });

  final int chapter;
  final int? initialAyah;
  final String editionId;
}

class PagedMushafArgs {
  const PagedMushafArgs({
    required this.ayat,
    required this.surahName,
    required this.surahNumber,
    this.initialSelectedAyah,
  });

  final List<Aya> ayat;
  final String surahName;
  final int surahNumber;
  final int? initialSelectedAyah;
}

class AyahArgs {
  const AyahArgs({required this.aya, required this.surah, this.tafsir});

  final Aya aya;
  final Surah surah;
  final String? tafsir;
}

Route<dynamic>? onGenerateRoute(RouteSettings s) {
  final name = s.name;

  if (name == AppRoutes.splash) {
    return _mat(const SplashScreen(), s);
  } else if (name == AppRoutes.home) {
    return _mat(const HomePage(), s);
  } else if (name == AppRoutes.gamificationHome) {
    return _mat(const ModernHomeScreen(), s);
  } else if (name == AppRoutes.mushaf) {
    final a = s.arguments;
    final args = a is MushafArgs ? a : const MushafArgs();
    if (a is MushafArgs && (a.initialAyah != null || a.chapter != 1)) {
      return _mat(
        MushafPage(
          chapter: args.chapter,
          editionId: args.editionId,
          initialAyah: args.initialAyah,
        ),
        s,
      );
    }
    return _mat(const SurahListPage(), s);
  } else if (name == AppRoutes.mushafPaged) {
    final a = s.arguments;
    if (a is PagedMushafArgs) {
      return MaterialPageRoute(
        settings: s,
        builder: (context) {
          return Consumer(
            builder: (context, ref, _) {
              final quran = ref.read(quranServiceProvider);
              const tafsirEdition = 'ar-tafsir-muyassar';

              return PagedMushaf(
                ayat: a.ayat,
                surahName: a.surahName,
                surahNumber: a.surahNumber,
                initialSelectedAyah: a.initialSelectedAyah,
                onAyahTap: (int ayahNumber, Aya aya) async {
                  final fakeSurah = Surah(
                    number: a.surahNumber,
                    name: a.surahName,
                    ayat: a.ayat,
                  );
                  final tafsirText = await quran.getAyahTafsir(
                    a.surahNumber,
                    ayahNumber,
                    tafsirEdition,
                  );

                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ayah,
                    arguments: AyahArgs(
                      aya: aya,
                      surah: fakeSurah,
                      tafsir: tafsirText,
                    ),
                  );
                },
                onAyahLongPress: (int ayahNumber, Aya aya) async {
                  final fakeSurah = Surah(
                    number: a.surahNumber,
                    name: a.surahName,
                    ayat: a.ayat,
                  );
                  final tafsirText = await quran.getAyahTafsir(
                    a.surahNumber,
                    ayahNumber,
                    tafsirEdition,
                  );

                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    AppRoutes.ayah,
                    arguments: AyahArgs(
                      aya: aya,
                      surah: fakeSurah,
                      tafsir: tafsirText,
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }

    return _mat(
      _routeMessagePage(
        'مسار المصحف',
        'mushafPaged يحتاج ayat + surahName + surahNumber',
      ),
      s,
    );
  } else if (name == AppRoutes.surahs) {
    return _mat(const SurahListPage(), s);
  } else if (name == AppRoutes.ayah) {
    final a = s.arguments;
    if (a is AyahArgs) {
      return _mat(
        AyahDetailPage(aya: a.aya, surah: a.surah, tafsir: a.tafsir),
        s,
      );
    }
    return _mat(
      _routeMessagePage('تفاصيل الآية', 'ayah route يحتاج Aya + Surah'),
      s,
    );
  } else if (name == AppRoutes.player) {
    return _mat(const PlayerPage(), s);
  } else if (name == AppRoutes.search) {
    return _mat(const SearchPage(), s);
  } else if (name == AppRoutes.bookmarks) {
    return _mat(const BookmarksPage(), s);
  } else if (name == AppRoutes.downloads) {
    return _mat(const dlp.DownloadsPage(embedded: false), s);
  } else if (name == AppRoutes.downloadDetail) {
    final a = s.arguments;
    if (a is Map<String, dynamic>) {
      final surah = a['surah'];
      final reciterId = a['reciterId'];
      final sNum = surah is int ? surah : int.tryParse('$surah');
      final rId = reciterId?.toString();
      if (sNum != null && rId != null && rId.isNotEmpty) {
        return _mat(ddp.DownloadDetailPage(surah: sNum, reciterId: rId), s);
      }
    }
    return _mat(
      _routeMessagePage(
        'التنزيل',
        'downloadDetail يحتاج {surah:int, reciterId:String}',
      ),
      s,
    );
  } else if (name == AppRoutes.downloadsLibrary) {
    return _mat(const DownloadsLibraryPage(), s);
  } else if (name == AppRoutes.about) {
    return _mat(const AboutPage(), s);
  } else if (name == AppRoutes.setting) {
    return _mat(const SettingsPage(), s);
  } else if (name == AppRoutes.goals) {
    return _mat(const GoalsPage(), s);
  } else if (name == AppRoutes.stats) {
    return _mat(const StatsPage(), s);
  } else if (name == AppRoutes.onboarding) {
    return _mat(const OnboardingPage(), s);
  } else if (name == AppRoutes.tafsir) {
    return _mat(const TafsirExplorerPage(), s);
  } else if (name == AppRoutes.tafsirReader) {
    final a = s.arguments;
    final args = a is TafsirArgs ? a : null;
    return _mat(
      TafsirReaderPage(
        initialEditionId: args?.sourceId,
        initialSurah: args?.chapter ?? 1,
        initialAyah: args?.ayah ?? 1,
      ),
      s,
    );
  } else if (name == AppRoutes.qibla) {
    return _mat(const QiblaPage(), s);
  } else if (name == AppRoutes.azkar) {
    return _mat(const AzkarTasbihPage(), s);
  }

  return _mat(_routeMessagePage('المسارات', 'Route not found'), s);
}

MaterialPageRoute _mat(Widget w, [RouteSettings? s]) {
  return MaterialPageRoute(builder: (_) => w, settings: s);
}

Widget _routeMessagePage(String title, String message) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: ProAppBar(
        title: title,
        subtitle: 'تعذر فتح الصفحة المطلوبة',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
