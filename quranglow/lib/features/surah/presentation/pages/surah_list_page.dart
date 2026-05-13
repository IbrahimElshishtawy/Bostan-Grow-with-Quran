import 'package:flutter/material.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/features/mushaf/presentation/pages/mushaf_page.dart';
import 'package:quranglow/core/widgets/shimmer_loading.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  bool _isSearching = false;
  bool _isLoading = true; // Show skeleton loader initially!
  final TextEditingController _searchController = TextEditingController();
  List<int> _filteredIndices = [];

  @override
  void initState() {
    super.initState();
    // Initialize with all indices
    _filteredIndices = List.generate(kSurahNamesAr.length, (i) => i);

    // Artificial delay so user sees the gorgeous skeleton loader requested
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
          if (surahName.contains(cleanQuery) ||
              surahNumStr.contains(query.trim())) {
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
          toolbarHeight: 80,
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
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: cs.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _isSearching = false;
                            _searchController.clear();
                            _filteredIndices = List.generate(
                              kSurahNamesAr.length,
                              (i) => i,
                            );
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
        body: _isLoading
            ? const SurahListSkeleton()
            : _filteredIndices.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
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
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  // ✨ Ultra-Premium GREEN Palette and Theme Adaptive Variables
                  final Color greenMain = cs.primary;
                  final Color greenAccent = cs.primary.withValues(alpha: 0.85);
                  final Color surfaceColor = isDark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white;
                  final Color textColorMain = isDark
                      ? Colors.grey[200]!
                      : const Color(0xFF2D3436);
                  final Color textColorSub = isDark
                      ? Colors.grey[500]!
                      : const Color(0xFF636E72);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : greenMain.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          // 🎨 Premium Green Gradient Border Injection
                          border: Border.all(
                            color: greenMain.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [surfaceColor, const Color(0xFF252528)]
                                : [
                                    surfaceColor,
                                    const Color(0xFFFEFDF8),
                                  ], // Pearl light variant
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            splashColor: greenMain.withValues(alpha: 0.1),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MushafPage(chapter: surahNumber),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                // Subtle Islamic Geometry Backing Icon (Transparent watermark)
                                Positioned(
                                  left: -20,
                                  bottom: -20,
                                  child: Icon(
                                    Icons.mosque_rounded,
                                    size: 100,
                                    color: greenMain.withValues(
                                      alpha: isDark ? 0.03 : 0.04,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    children: [
                                      // 1. Islamic-style Gold Badge Number
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Transform.rotate(
                                            angle:
                                                0.785, // 45 degrees rotate for star look
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: greenMain.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: greenAccent,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _toArabicDigits(surahNumber),
                                            style: TextStyle(
                                              color: isDark
                                                  ? greenMain
                                                  : cs.primary,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 22),
                                      // 2. Dynamic text details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              kSurahNamesAr[originalIndex],
                                              style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w800,
                                                color: textColorMain,
                                                fontFamily:
                                                    'KFGQPC Uthmanic Script', // Try to force arabic font
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.auto_awesome,
                                                  size: 12,
                                                  color: greenMain.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'سورة ${_toArabicDigits(surahNumber)}',
                                                  style: TextStyle(
                                                    color: textColorSub,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 3. Premium Gold Tail Icon
                                      Icon(
                                        Icons
                                            .arrow_back_ios_new_rounded, // Inverted for RTL naturally? Handled automatically by directionality
                                        size: 16,
                                        color: greenMain.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
