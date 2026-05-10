import 'package:flutter/material.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/features/mushaf/presentation/pages/mushaf_page.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredIndices = [];

  @override
  void initState() {
    super.initState();
    // Initialize with all indices
    _filteredIndices = List.generate(kSurahNamesAr.length, (i) => i);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredIndices = List.generate(kSurahNamesAr.length, (i) => i);
      } else {
        final cleanQuery = _normalizeArabic(query);
        _filteredIndices = [];
        for (int i = 0; i < kSurahNamesAr.length; i++) {
          final surahName = _normalizeArabic(kSurahNamesAr[i]);
          // Match by name or match by explicit Surah number string input
          final surahNumStr = (i + 1).toString();
          if (surahName.contains(cleanQuery) || surahNumStr.contains(query.trim())) {
            _filteredIndices.add(i);
          }
        }
      }
    });
  }

  // Utility to remove basic Arabic diacritics for easier fuzzy matching
  String _normalizeArabic(String text) {
    String result = text;
    // Replace common alternative character formats
    result = result.replaceAll(RegExp(r'[إأآا]'), 'ا');
    result = result.replaceAll('ة', 'ه');
    result = result.replaceAll('ى', 'ي');
    // Remove common Tashkeel marks
    result = result.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
    return result.trim();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 94,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          flexibleSpace: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  cs.primary.withValues(alpha: 0.16),
                  cs.tertiary.withValues(alpha: 0.08),
                  cs.surface,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن اسم السورة...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                            _filteredIndices = List.generate(kSurahNamesAr.length, (i) => i);
                          });
                        },
                      ),
                      filled: true,
                      fillColor: cs.surface.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : Column(
                    key: const ValueKey('app_bar_titles'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السور',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ابدأ من السورة ثم انتقل مباشرة إلى القراءة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            if (!_isSearching)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: Icon(Icons.search_rounded, color: cs.primary, size: 28),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: IconButton.filledTonal(
                tooltip: 'رجوع',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface.withValues(alpha: 0.82),
                  foregroundColor: cs.primary,
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ],
        ),
        body: _filteredIndices.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'لم يتم العثور على نتائج',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                itemCount: _filteredIndices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, listIndex) {
                  final originalIndex = _filteredIndices[listIndex];
                  final surahNumber = originalIndex + 1;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A2E21).withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.06),
                            width: 1.2,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFFFDFDFD),
                              Color(0xFFF4F9EC),
                            ],
                            stops: [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MushafPage(chapter: surahNumber),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  // 1. Modern Surah Index Badge
                                  Container(
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFBDE156).withValues(alpha: 0.1),
                                          const Color(0xFF8DA740).withValues(alpha: 0.25),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF8DA740).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      _toArabicDigits(surahNumber),
                                      style: const TextStyle(
                                        color: Color(0xFF1A3022),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 2. Text Information
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          kSurahNamesAr[originalIndex],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A3022),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'سورة رقم ${_toArabicDigits(surahNumber)}',
                                          style: TextStyle(
                                            color: const Color(0xFF1A3022).withValues(alpha: 0.55),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 3. Premium Soft Trailing Arrow Button
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A3022).withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 22,
                                      color: Color(0xFF1A3022),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _toArabicDigits(int n) {
    const east = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final b = StringBuffer();
    for (final ch in n.toString().split('')) {
      final d = int.tryParse(ch);
      b.write(d == null ? ch : east[d]);
    }
    return b.toString();
  }
}
