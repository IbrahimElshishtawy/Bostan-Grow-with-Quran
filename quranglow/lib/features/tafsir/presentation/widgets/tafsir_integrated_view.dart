// ignore_for_file: duplicate_ignore, unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/ayah_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/selection_card.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_card.dart';

class TafsirIntegratedView extends ConsumerStatefulWidget {
  const TafsirIntegratedView({super.key});

  @override
  ConsumerState<TafsirIntegratedView> createState() =>
      _TafsirIntegratedViewState();
}

class _TafsirIntegratedViewState extends ConsumerState<TafsirIntegratedView> {
  String? _editionId;
  String? _editionName;
  int _surah = 1;
  int _ayah = 1;

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

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
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
            // ignore: unused_result
            ref.refresh(tafsirForAyahProvider((_surah, _ayah, id)).future);
          },
          onSurahChange: (v, _) {
            setState(() {
              _surah = v;
              _ayah = 1;
            });
            if (_editionId != null) {
              ref.refresh(tafsirForAyahProvider((v, 1, _editionId!)).future);
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
        const SizedBox(height: 20),
        AyahCard(surahName: surahName, ayah: _ayah, ayahText: ayahText),
        const SizedBox(height: 16),
        TafsirCard(tafsir: tafsir, editionName: _editionName),
        const SizedBox(height: 32),
      ],
    );
  }
}
