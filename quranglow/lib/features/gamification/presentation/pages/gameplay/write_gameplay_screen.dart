import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/core/widgets/loading_widget.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/heart_timer_display.dart';
import 'package:quranglow/features/gamification/application/gamification_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class WriteGameplayScreen extends ConsumerStatefulWidget {
  final GameLevel level;

  const WriteGameplayScreen({super.key, required this.level});

  @override
  ConsumerState<WriteGameplayScreen> createState() => _WriteGameplayScreenState();
}

class _WriteGameplayScreenState extends ConsumerState<WriteGameplayScreen> {
  int _currentAyahIndex = 0;
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _error;

  List<String> _correctWords = [];
  List<String> _shuffledWords = [];
  List<String> _userWords = [];

  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    // Pre-check: Ensure user actually has hearts to begin with!
    final initialHearts = ref.read(gamificationControllerProvider).valueOrNull?.userProfile.hearts ?? 0;
    if (initialHearts <= 0) {
      // Temporarily pause loading and show prompt
      if (mounted) setState(() => _isLoading = true); // Keep spinning slightly while prompt is up
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRefillPrompt());
      return;
    }

    if (mounted) setState(() => _isLoading = true); // Ensure loader shows on restart

    try {
      final fetched = await ref.read(quranApiServiceProvider).getAyahRange(
        widget.level.surahId,
        widget.level.ayahStart,
        widget.level.ayahEnd,
      );

      // ✨ RECALL PREVIOUS PROGRESS FROM LOCAL CACHE! ✨
      final prefs = await SharedPreferences.getInstance();
      final savedIdx = prefs.getInt('write_prog_${widget.level.id}') ?? 0;
      
      // Sanity cap the index just in case
      final finalIdx = savedIdx >= fetched.length ? 0 : savedIdx;

      if (mounted) {
        setState(() {
          _ayahs = fetched;
          _currentAyahIndex = finalIdx;
          _isLoading = false;
          _setupCurrentAyah();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _setupCurrentAyah() {
    if (_currentAyahIndex >= _ayahs.length) return;
    
    final cleanText = _ayahs[_currentAyahIndex].text.replaceAll(RegExp(r'\s+'), ' ').trim();
    _correctWords = cleanText.split(' ');
    
    _shuffledWords = List.from(_correctWords)..shuffle(math.Random());
    _userWords = [];
  }

  void _onWordTap(String word) {
    // Check if it matches the next required word in the sequence
    final nextRequiredWordIndex = _userWords.length;
    final requiredWord = _correctWords[nextRequiredWordIndex];

    if (word == requiredWord) {
      setState(() {
        _userWords.add(word);
        _shuffledWords.remove(word);
        
        // Check if sentence complete!
        if (_userWords.length == _correctWords.length) {
          Future.delayed(const Duration(milliseconds: 600), () {
             _advanceToNextAyah();
          });
        }
      });
    } else {
      // WRONG!
      _deductHeart();
    }
  }

  Future<void> _deductHeart() async {
    final controller = ref.read(gamificationControllerProvider.notifier);
    await controller.loseHeart();
    
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ! انتبه للكلمة التالية ❌', textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 600),
        ),
      );
      
      // Verify live heart state post-deduction
      final liveHearts = ref.read(gamificationControllerProvider).valueOrNull?.userProfile.hearts ?? 0;
      if (liveHearts <= 0) {
        _showRefillPrompt();
      }
    }
  }

  void _showRefillPrompt() {
    final cs = Theme.of(context).colorScheme;
    final List<String> spiritualQuotes = [
      "'{وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا}' - سورة الطلاق",
      "'{وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ}' - سورة البقرة",
      "'{أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ}' - سورة الرعد",
      "'{إِنَّ مَعَ الْعُسْرِ يُسْرًا}' - سورة الشرح",
      "قَالَ رَسُولُ اللَّهِ ﷺ: 'اسْتَعِنْ بِاللَّهِ وَلَا تَعْجَزْ'",
    ];
    final String randomQuote = spiritualQuotes[DateTime.now().second % spiritualQuotes.length];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'تذكر واستعن بالله',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              randomQuote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'KFGQPC Uthmanic Script',
                fontSize: 18,
                color: cs.primary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'الخطأ هو طريق التعلم، لا تحزن.. استمر في رحلتك وسيعينك الله.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _refillHeartsFreely(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.favorite_rounded),
              label: const Text(
                'استمر بنور الله',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pop(context);
            },
            child: Text(
              'خروج مؤقت',
              style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refillHeartsFreely(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'جاري تجديد العزم...',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      Navigator.pop(context);
      final success = await ref
          .read(gamificationControllerProvider.notifier)
          .grantRewardAdHearts();
      
      if (success && mounted) {
        PremiumFeedbackService.grandCelebration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة المحاولات، انطلق ببركة الله! ✨', textAlign: TextAlign.center),
            backgroundColor: Colors.green,
          ),
        );
        if (_ayahs.isEmpty) _loadLevelData();
      }
    }
  }

  Future<void> _advanceToNextAyah() async {
    if (_currentAyahIndex < _ayahs.length - 1) {
      final nextIdx = _currentAyahIndex + 1;
      
      // ✨ PERSIST PROGRESS! ✨
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('write_prog_${widget.level.id}', nextIdx);
      
      if (mounted) {
        setState(() {
          _currentAyahIndex = nextIdx;
          _setupCurrentAyah();
        });
      }
    } else {
      // COMPLETION!
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('write_prog_${widget.level.id}'); // Wipe cache so they can replay
      
      if (mounted) {
        setState(() {
          _currentAyahIndex++; // flag complete
        });
      }
      await ref.read(gamificationControllerProvider.notifier).completeSubTask(widget.level.id, 'write');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentAyahIndex >= _ayahs.length && _ayahs.isNotEmpty;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text('تحدي بناء وتركيب الآيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
          centerTitle: true,
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          elevation: 0,
          iconTheme: IconThemeData(color: cs.onSurface),
          actions: [
            // GLORIOUS REAL-TIME HEART COUNTER FROM GAME ENGINE!
            Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(gamificationControllerProvider);
                final profile = state.valueOrNull?.userProfile;
                if (profile == null) return const SizedBox();
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: HeartTimerDisplay(
                    profile: profile,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: LoadingWidget(message: 'جاري تجهيز الآيات...'))
            : _error != null
                ? Center(child: Text('خطأ: $_error'))
                : isDone 
                    ? _buildWinState()
                    : _buildGameplayLayout(cs, isDark),
      ),
    );
  }

  Widget _buildGameplayLayout(ColorScheme cs, bool isDark) {
    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: _currentAyahIndex / _ayahs.length,
          backgroundColor: cs.surfaceContainerHighest,
          color: GameificationColors.primaryGreen,
          minHeight: 6,
        ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'الآية ${_currentAyahIndex + 1} من ${_ayahs.length}',
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
          ),
        ),

        // 1. Construction Area
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 10,
                children: [
                  ..._userWords.map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(w, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Kitab')),
                  ).animate().scale(curve: Curves.easeOutBack)),
                  
                  // The upcoming slot skeleton
                  if (_userWords.length < _correctWords.length)
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add, color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 16),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 2. Bank of words
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: _shuffledWords.map((word) {
                  return GestureDetector(
                    onTap: () => _onWordTap(word),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 5, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          fontFamily: 'Kitab',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 90, color: Colors.orange)
                .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text(
              'تحدي التركيب تم بنجاح! 🎉',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen),
            ),
            const SizedBox(height: 12),
            const Text(
              'كتابة آيات القرآن الكريم وتركيبها يرسخ الحفظ والفهم في القلب والذاكرة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameificationColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('العودة للمسار 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
