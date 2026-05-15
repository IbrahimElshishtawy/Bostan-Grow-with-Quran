// lib/features/ui/pages/tafsir/tafsir_reader_page.dart
// ignore_for_file: unused_result
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/ayah_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/selection_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_card.dart';

class TafsirExplorerPage extends ConsumerStatefulWidget {
  const TafsirExplorerPage({
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
  ConsumerState<TafsirExplorerPage> createState() => _TafsirExplorerPageState();
}

class _TafsirExplorerPageState extends ConsumerState<TafsirExplorerPage> {
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

    // حدد النوع صراحةً
    final AsyncValue<String> tafsir = (_editionId == null)
        ? const AsyncValue<String>.loading()
        : ref.watch(tafsirForAyahProvider((_surah, _ayah, _editionId!)));

    final quranMetadata = ref.watch(quranMetadataProvider);
    final AsyncValue<Surah> selectedSurah = ref.watch(quranSurahProvider((_surah, 'quran-uthmani')));

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
        appBar: const ProAppBar(
          title: 'التفسير',
          subtitle: 'استكشف السور والآيات واختر التفسير المناسب',
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    tafsirForAyahProvider((_surah, _ayah, _editionId!)).future,
                  );
                }
              },
              onAyahChange: (v) {
                setState(() => _ayah = v.clamp(1, maxAyat));
                if (_editionId != null) {
                  ref.refresh(
                    tafsirForAyahProvider((_surah, _ayah, _editionId!)).future,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            AyahCard(surahName: surahName, ayah: _ayah, ayahText: ayahText),
            const SizedBox(height: 12),
            TafsirCard(tafsir: tafsir, editionName: _editionName),
          ],
        ),
      ),
    );
  }
}
