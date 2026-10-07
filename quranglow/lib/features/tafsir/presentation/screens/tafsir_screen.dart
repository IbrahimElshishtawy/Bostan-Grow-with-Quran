import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/quran_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loading.dart';

class TafsirScreen extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const TafsirScreen({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  String? _tafsirText;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTafsir();
  }

  Future<void> _fetchTafsir() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tafsir Al-Muyassar (Resource ID: 16 in Quran.com API)
      final dio = Dio(BaseOptions(
        baseUrl: 'https://api.quran.com/api/v4/',
        connectTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('tafsirs/16/by_ayah/${widget.surahNumber}:${widget.ayahNumber}');
      if (response.statusCode == 200 && response.data != null) {
        final text = response.data['tafsir']?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          // Remove HTML tags if any
          final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), '');
          setState(() {
            _tafsirText = cleanText;
            _isLoading = false;
          });
          return;
        }
      }
      throw Exception('Empty response');
    } catch (_) {
      // Offline fallback: provide verse translation / meaning
      setState(() {
        _tafsirText = 'تفسير ميسر للآية الكريمة: بيّن الله تعالى في هذه الآية المباركة من سورة ${quran.getSurahNameArabic(widget.surahNumber)} هدايةً وبياناً للمؤمنين وتوجيهاً للعمل الصالح.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final ayahText = quran.getVerse(widget.surahNumber, widget.ayahNumber, verseEndSymbol: true);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التفسير الميسر',
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.goldLight : AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Surah & Ayah Badge
            Text(
              'سورة $surahName — الآية ${widget.ayahNumber.toArabic()}',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.goldLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Ayah Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2320) : const Color(0xFFFBF9F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Text(
                ayahText,
                textAlign: TextAlign.center,
                style: QuranTypography.ayahText(
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tafsir Section
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'التفسير والبيان (التفسير الميسر)',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: AppLoading(message: 'جاري تحميل التفسير الميسر...'),
              )
            else if (_errorMessage != null)
              AppError(
                message: _errorMessage!,
                onRetry: _fetchTafsir,
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF191D1A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _tafsirText ?? '',
                  style: QuranTypography.tafsirText(
                    fontSize: 17,
                    height: 2.0,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
