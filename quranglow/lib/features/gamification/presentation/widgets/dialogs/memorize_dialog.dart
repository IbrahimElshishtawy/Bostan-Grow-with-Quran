import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';

class InteractiveMemorizeDialog extends ConsumerStatefulWidget {
  const InteractiveMemorizeDialog({
    required this.level,
    required this.onComplete,
    super.key,
  });

  final GameLevel level;
  final VoidCallback onComplete;

  @override
  ConsumerState<InteractiveMemorizeDialog> createState() =>
      _InteractiveMemorizeDialogState();
}

class _InteractiveMemorizeDialogState
    extends ConsumerState<InteractiveMemorizeDialog> {
  late Future<List<Ayah>> _fetchFuture;
  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _isSuccessSound = false;
  List<Ayah> _ayahs = [];
  int _mistakes = 0;

  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textController = TextEditingController();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _speechInput = "";

  @override
  void initState() {
    super.initState();

    // Ensure immediate check for existing heart balance before startup!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialHearts =
          ref
              .read(gamificationControllerProvider)
              .valueOrNull
              ?.userProfile
              .hearts ??
          0;
      if (initialHearts <= 0) {
        _showRefillPrompt();
      }
    });

    _initSpeech();
    _fetchFuture = ref
        .read(quranApiServiceProvider)
        .getAyahRange(
          widget.level.surahId,
          widget.level.ayahStart,
          widget.level.ayahEnd,
        )
        .then((list) {
          if (mounted) setState(() => _ayahs = list);
          return list;
        });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final hasSpeech = await _speechToText.initialize(
        onError: (e) => debugPrint('Memorize Speech Error: $e'),
        onStatus: (s) => debugPrint('Memorize Speech Status: $s'),
      );
      if (mounted) {
        setState(() => _speechEnabled = hasSpeech);
      }
    } catch (e) {
      debugPrint('Failed to init STT in Dialog: $e');
    }
  }

  Future<void> _toggleListening(String targetWord) async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تفعيل الميكروفون، يرجى المحاولة مجدداً.'),
        ),
      );
      _initSpeech();
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _speechInput = "";
      });
      await _speechToText.listen(
        onResult: (res) => _handleResult(res, targetWord),
        localeId: 'ar-SA',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
      );
    }
  }

  void _handleResult(SpeechRecognitionResult result, String targetWord) {
    if (!mounted) return;
    setState(() {
      _speechInput = result.recognizedWords;
    });

    // Immediately check if any word matches
    final words = _normalizeArabic(result.recognizedWords).split(' ');
    final target = _normalizeArabic(targetWord);

    for (var w in words) {
      if (w.isEmpty) continue;

      // Ultra-Fuzzy Relaxed Check:
      bool match =
          (w == target ||
          target.contains(w) ||
          w.contains(target) ||
          _calculateCharacterOverlap(w, target) >= 0.6);

      if (match) {
        _speechToText.stop();
        setState(() {
          _isListening = false;
          _isRevealed = true;
          _isSuccessSound = true; // Trigger visual effect
        });
        // Clear feedback chime after 1s
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _isSuccessSound = false);
        });
        break;
      }
    }
  }

  void _checkManualAnswer(String targetWord) {
    final input = _textController.text.trim();
    if (input.isEmpty) return;
    final normInput = _normalizeArabic(input);
    final target = _normalizeArabic(targetWord);
    bool match =
        (normInput == target ||
        target.contains(normInput) ||
        normInput.contains(target) ||
        _calculateCharacterOverlap(normInput, target) >= 0.6);

    if (match) {
      FocusScope.of(context).unfocus();
      setState(() {
        _isRevealed = true;
        _isSuccessSound = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isSuccessSound = false);
      });
    } else {
      _deductHeart();
    }
  }

  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]'), '')
        .replaceAll(RegExp(r'[إأآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  double _calculateCharacterOverlap(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    final c1 = s1.split('');
    final c2 = s2.split('');
    int match = 0;
    List<String> pool = List.from(c2);
    for (var c in c1) {
      if (pool.contains(c)) {
        match++;
        pool.remove(c);
      }
    }
    final min = c1.length < c2.length ? c1.length : c2.length;
    return min == 0 ? 0.0 : match / min;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      contentPadding: const EdgeInsets.all(20),
      content: FutureBuilder<List<Ayah>>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            );
          }

          if (snapshot.hasError || _ayahs.isEmpty) {
            return const SizedBox(
              height: 200,
              child: Center(child: Text('خطأ في تحميل بيانات التثبيت')),
            );
          }

          final bool done = _currentIndex >= _ayahs.length;
          if (done) return _buildFinalSuccess(cs);

          final currentAyah = _ayahs[_currentIndex];
          final words = currentAyah.text.split(' ');
          final hiddenWord = words.last;
          final leadingText = words.sublist(0, words.length - 1).join(' ');

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Colors.purple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تثبيت الحفظ (${_currentIndex + 1}/${_ayahs.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'قل الكلمة الأخيرة بصوتك للكشف عنها 🎯',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // The Card showing the text and the blank spot
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isSuccessSound
                          ? Colors.green
                          : cs.outlineVariant.withValues(alpha: 0.5),
                      width: _isSuccessSound ? 2 : 1,
                    ),
                    boxShadow: [
                      if (_isSuccessSound)
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 12,
                    children: [
                      Text(
                        leadingText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'KFGQPC Uthmanic Script',
                          height: 1.6,
                          color: cs.onSurface,
                        ),
                      ),

                      // The Secret Hidden Word UI
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: a,
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: _isRevealed
                            ? Text(
                                hiddenWord,
                                key: const ValueKey('revealed'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontFamily: 'KFGQPC Uthmanic Script',
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Container(
                                key: const ValueKey('hidden'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '.....',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (!_isRevealed) ...[
                  // Voice Control Area
                  Text(
                    _isListening
                        ? "استمع الآن..."
                        : (_speechInput.isNotEmpty
                              ? "حاولت قول: $_speechInput"
                              : "اضغط للبدء"),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isListening ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _toggleListening(hiddenWord),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isListening)
                          const SizedBox(
                                height: 75,
                                width: 75,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 2.seconds),
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isListening
                                            ? Colors.redAccent
                                            : Colors.blue)
                                        .withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'أو أكتب الإجابة',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _textController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'أكتب الكلمة هنا...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          onPressed: () => _checkManualAnswer(hiddenWord),
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _checkManualAnswer(hiddenWord),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _isRevealed = true),
                    child: Text(
                      'لا أتذكرها، كشف الكلمة',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ] else ...[
                  // Success State actions
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 40,
                  ).animate().scale(duration: 300.ms, curve: Curves.bounceOut),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _goToNext,
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _currentIndex < _ayahs.length - 1
                            ? 'الآية التالية'
                            : 'إنهاء المهمة',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _goToNext() {
    if (_currentIndex < _ayahs.length - 1) {
      setState(() {
        _currentIndex++;
        _isRevealed = false;
        _speechInput = "";
        _textController.clear(); // Clear the controller for new word!
      });
    } else {
      setState(() => _currentIndex++);
      widget.onComplete();
    }
  }

  Widget _buildFinalSuccess(ColorScheme cs) {
    // ✨ Smart Star Calculation System! ✨
    int earnedStars = 3;
    String praiseTitle = 'إنجاز مثالي! 🌟';
    String praiseDesc = 'لم ترتكب أي خطأ، حفظك كالنقش على الحجر!';
    
    if (_mistakes > 2) {
      earnedStars = 1;
      praiseTitle = 'عمل رائع، استمر! 💪';
      praiseDesc = 'أكملت المهمة بنجاح، تدرب أكثر للحصول على العلامة الكاملة!';
    } else if (_mistakes > 0) {
      earnedStars = 2;
      praiseTitle = 'حفظ قوي! ✨';
      praiseDesc = 'أداء رائع جداً، أوشكت على بلوغ الإتقان التام!';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🌟 THE PREMIUM STAR DISPLAY ROW!
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final bool isEarned = index < earnedStars;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                index == 1 ? Icons.star_rounded : Icons.star_rounded, // could scale middle larger
                size: index == 1 ? 65 : 50,
                color: isEarned ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
              )
              .animate(target: isEarned ? 1 : 0)
              .scale(
                duration: 500.ms, 
                delay: (200 * index).ms, 
                curve: Curves.elasticOut
              )
              .then()
              .shimmer(duration: 2.seconds, color: Colors.white54),
            );
          }),
        ),
        const SizedBox(height: 24),
        
        // 🏆 TITLE WITH GLOW
        Text(
          praiseTitle,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: cs.primary,
            letterSpacing: 0.5,
          ),
        ).animate().fade().slideY(begin: 0.3, end: 0),
        
        const SizedBox(height: 12),
        
        // 📝 DESCRIPTIVE FEEDBACK
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            praiseDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15, 
              color: cs.onSurfaceVariant,
              height: 1.4
            ),
          ),
        ).animate().fade(delay: 300.ms),
        
        const SizedBox(height: 32),
        
        // 🚀 CALL TO ACTION
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'متابعة الرحلة 🚀',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ).animate().scale(delay: 600.ms, duration: 400.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  // ❤️ HEARTS SYSTEM
  Future<void> _deductHeart() async {
    final controller = ref.read(gamificationControllerProvider.notifier);
    await controller.loseHeart();
    if (mounted) setState(() => _mistakes++);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ! تم خصم محاولة 💔', textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 1),
        ),
      );

      final liveHearts =
          ref
              .read(gamificationControllerProvider)
              .valueOrNull
              ?.userProfile
              .hearts ??
          0;
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
        title: const Text(
          'نفذت المحاولات! 💔',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'يمكنك الانتظار لإعادة الشحن، أو مشاهدة فيديو لاستعادة المحاولات والاستمرار!',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('خروج'),
          ),
          ElevatedButton.icon(
            onPressed: () => _simulateWatchAd(c),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('مشاهدة إعلان 🎁'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateWatchAd(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog.fullscreen(
          backgroundColor: Colors.black87,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Icon(
                  Icons.movie_creation_rounded,
                  size: 50,
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 16),
                Text(
                  'جاري تشغيل الإعلان...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      Navigator.pop(context);
      final success = await ref
          .read(gamificationControllerProvider.notifier)
          .grantRewardAdHearts();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة المحاولات! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
