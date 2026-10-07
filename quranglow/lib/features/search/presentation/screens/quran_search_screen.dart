import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/quran_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../quran/presentation/screens/mushaf_screen.dart';
import '../../domain/services/quran_search_engine.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SearchAyahResult> _results = [];
  bool _isSearching = false;

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final res = QuranSearchEngine.search(query);
    setState(() {
      _results = res;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'البحث في القرآن الكريم',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'ابحث عن آية أو كلمة (مثال: الصابرين، الرحمن)...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2320) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results summary
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'نتائج البحث: ${_results.length.toArabic()} آية',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Results List
          Expanded(
            child: _controller.text.isEmpty
                ? const AppEmpty(
                    title: 'ابحث في آيات القرآن الكريم',
                    subtitle: 'يمكنك البحث عن أي كلمة أو عبارة، يدعم البحث بدون تشكيل',
                    icon: Icons.search_rounded,
                  )
                : _results.isEmpty
                    ? const AppEmpty(
                        title: 'لم يتم العثور على نتائج',
                        subtitle: 'تأكد من كتابة الكلمة بشكل صحيح وحاول مجدداً',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MushafScreen(initialPage: item.pageNumber),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E2320) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'سورة ${item.surahName} — الآية ${item.ayahNumber.toArabic()}',
                                        style: GoogleFonts.amiri(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.goldLight : AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'صفحة ${item.pageNumber.toArabic()}',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    item.textArabic,
                                    textDirection: TextDirection.rtl,
                                    style: QuranTypography.ayahText(
                                      fontSize: 16,
                                      height: 1.8,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
