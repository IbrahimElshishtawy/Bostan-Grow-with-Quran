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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('نفذت المحاولات! 💔', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'يمكنك الانتظار لإعادة الشحن، أو مشاهدة فيديو لاستعادة المحاولات فوراً والاستمرار!',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit screen
            },
            child: const Text('خروج'),
          ),
          ElevatedButton.icon(
            onPressed: () => _simulateWatchAd(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text(
              'مشاهدة إعلان واستعادة المحاولات 🎁',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎬 SIMULATED AD EXPERIENCE!
  Future<void> _simulateWatchAd(BuildContext dialogContext) async {
    // 1. Close the existing prompt dialog
    Navigator.pop(dialogContext);

    // 2. Show a cool 'Ad Player' simulation overlay!
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Force watch!
        child: Dialog.fullscreen(
          backgroundColor: Colors.black87,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 24),
                const Icon(Icons.movie_creation_rounded, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  'جاري تشغيل الفيديو المكافيء...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'استعادة المحاولات في غضون ثوانٍ معدودة',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 3. Wait 2 seconds for realism!
    await Future.delayed(const Duration(milliseconds: 2500));

    // 4. Remove simulator and award hearts!
    if (mounted) {
      Navigator.pop(context); // Close Ad simulator
      
      final success = await ref.read(gamificationControllerProvider.notifier).grantRewardAdHearts();
      
      if (success && mounted) {
        PremiumFeedbackService.grandCelebration();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة +3 محاولات بنجاح! 🎉', textAlign: TextAlign.center),
            backgroundColor: Colors.green,
          )
        );

        // ✨ Resume load cascade if were not loaded!
        if (_ayahs.isEmpty) {
          _loadLevelData();
        }
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
      ref.read(gamificationControllerProvider.notifier).completeSubTask(widget.level.id, 'write');
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
