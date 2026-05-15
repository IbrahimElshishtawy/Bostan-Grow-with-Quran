import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'ayah_picker.dart';

class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.editions,
    required this.quranAll,
    required this.editionId,
    required this.surah,
    required this.ayah,
    required this.onEditionChange,
    required this.onSurahChange,
    required this.onAyahChange,
  });

  final AsyncValue<List<Map<String, String>>> editions;
  final AsyncValue<List<Surah>> quranAll;
  final String? editionId;
  final int surah;
  final int ayah;
  final void Function(String id, String name) onEditionChange;
  final void Function(int surah, int maxAyat) onSurahChange;
  final void Function(int ayah) onAyahChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color primaryColor = const Color(0xFF1B4D3E); // Deep Teal
    final Color accentColor = const Color(0xFFD4AF37); // Gold

    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.black26 : Colors.white70,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.15)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : primaryColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Tajawal',
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2921) : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.settings_suggest_outlined, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'تخصيص العرض',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: editions.when(
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (e, _) => const Icon(Icons.error_outline, color: Colors.red),
                  data: (list) => DropdownButtonFormField<String>(
                    value: editionId,
                    decoration: fieldDecoration.copyWith(labelText: 'المصدر'),
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Tajawal'),
                    items: list.map((m) => DropdownMenuItem(value: m['id']!, child: Text(m['name']!, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final m = list.firstWhere((e) => e['id'] == v);
                      onEditionChange(v, m['name']!);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: quranAll.when(
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (e, _) => const Icon(Icons.error_outline, color: Colors.red),
                  data: (all) => DropdownButtonFormField<int>(
                    value: surah.clamp(1, all.length),
                    decoration: fieldDecoration.copyWith(labelText: 'السورة'),
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Tajawal'),
                    isExpanded: true,
                    items: [
                      for (int i = 0; i < all.length; i++)
                        DropdownMenuItem(value: i + 1, child: Text(all[i].name)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      onSurahChange(v, all[v - 1].ayat.length);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: quranAll.maybeWhen(
                  data: (all) {
                    final fixedSurah = surah.clamp(1, all.length);
                    final maxAyat = all[fixedSurah - 1].ayat.length;
                    return AyahPicker(
                      maxAyat: maxAyat,
                      ayah: ayah.clamp(1, maxAyat),
                      onAyahChange: onAyahChange,
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

