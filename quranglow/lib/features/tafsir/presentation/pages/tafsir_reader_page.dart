// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/di/tafsir_providers.dart'
    hide quranAllProvider, tafsirForAyahProvider;
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/ayah_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/selection_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_card.dart';

class TafsirReaderPage extends ConsumerStatefulWidget {
  const TafsirReaderPage({
    super.key,
    this.initialEditionId,
    this.initialEditionName,
    this.initialSurah = 1,
    this.initialAyah = 1,
  });

  final String? initialEditionId;
  final String? initialEditionName;
  final int initialSurah;
  final int initialAyah;

  @override
  ConsumerState<TafsirReaderPage> createState() => _TafsirReaderPageState();
}

class _TafsirReaderPageState extends ConsumerState<TafsirReaderPage> {
  String? _editionId;
  String? _editionName;
  int _surah = 1;
  int _ayah = 1;

  @override
  void initState() {
    super.initState();
    _editionId = widget.initialEditionId;
    _editionName = widget.initialEditionName;
    _surah = widget.initialSurah;
    _ayah = widget.initialAyah;
  }

  @override
  Widget build(BuildContext context) {
    final editions = ref.watch(tafsirEditionsProvider);
    editions.whenData((list) {
      if ((_editionId == null || _editionId!.isEmpty) && list.isNotEmpty) {
        setState(() {
          _editionId = list.first['id']!;
          _editionName = list.first['name']!;
        });
      }
    });

    final quranMetadata = ref.watch(quranMetadataProvider);
    final AsyncValue<Surah> selectedSurah = ref.watch(quranSurahProvider((_surah, 'quran-uthmani')));
    final AsyncValue<String> tafsir = (_editionId == null)
        ? const AsyncValue<String>.loading()
        : ref.watch(tafsirForAyahProvider((_surah, _ayah, _editionId!)));

    final meta = quranMetadata[_surah - 1];
    String surahName = meta.name;
    int maxAyat = meta.ayatCount;
    String ayahText = '';

    selectedSurah.whenData((s) {
      if (_ayah >= 1 && _ayah <= s.ayat.length) {
        ayahText = s.ayat[_ayah - 1].text;
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: ProAppBar(
          title: 'خزانة التفسير',
          subtitle: 'تدبّر معاني الآيات من خلال أوثق كتب التفسير',
          actions: [
            if (_editionId != null)
              IconButton(
                tooltip: 'تنزيل تفسير السورة',
                onPressed: () {
                  ref.refresh(prefetchTafsirSurahProvider((_editionId!, _surah)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('جارٍ تنزيل التفسير للقراءة دون اتصال...'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_download_rounded),
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // Selection Section
              SelectionCard(
                editions: editions,
                quranMetadata: quranMetadata,
                editionId: _editionId,
                surah: _surah,
                ayah: _ayah,
                ayahText: ayahText,
                onEditionChange: (id, name) {
                  setState(() {
                    _editionId = id;
                    _editionName = name;
                  });
                  ref.refresh(tafsirForAyahProvider((_surah, _ayah, id)).future);
                },
                onSurahChange: (v, _) {
                  setState(() {
                    _surah = v;
                    _ayah = 1;
                  });
                  if (_editionId != null) {
                    ref.refresh(
                      tafsirForAyahProvider((v, 1, _editionId!)).future,
                    );
                  }
                },
                onAyahChange: (v) {
                  final nextAyah = v.clamp(1, maxAyat);
                  setState(() => _ayah = nextAyah);
                  if (_editionId != null) {
                    ref.refresh(
                      tafsirForAyahProvider((_surah, nextAyah, _editionId!)).future,
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // The Sacred Text Card
              AyahCard(surahName: surahName, ayah: _ayah, ayahText: ayahText),
              const SizedBox(height: 20),

              // The Professional Tafsir Card
              TafsirCard(tafsir: tafsir, editionName: _editionName),
              
              const SizedBox(height: 40),
              
              // Decorative footer
              Opacity(
                opacity: 0.3,
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'كُلُّ نَفْسٍ ذَائِقَةُ الْمَوْتِ ۗ وَإِنَّمَا تُوَفَّوْنَ أُجُورَكُمْ يَوْمَ الْقِيَامَةِ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Tajawal',
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
