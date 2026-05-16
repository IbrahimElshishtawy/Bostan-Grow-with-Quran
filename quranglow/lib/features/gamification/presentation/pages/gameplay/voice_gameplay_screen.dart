import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/core/widgets/loading_widget.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/heart_timer_display.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceGameplayScreen extends ConsumerStatefulWidget {
  final GameLevel level;
  const VoiceGameplayScreen({super.key, required this.level});

  @override
  ConsumerState<VoiceGameplayScreen> createState() => _VoiceGameplayScreenState();
}

class _VoiceGameplayScreenState extends ConsumerState<VoiceGameplayScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpoken = "";

  int _currentAyahIndex = 0;
  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _error;

  // Validation State
  List<String> _targetWords = [];
  List<WordStatus> _wordStatuses = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadLevelData();
  }

  Future<void> _initSpeech() async {
    try {
      // Using dynamic catch to capture both dart and platform side MissingPluginException silently
      final initialized = await _speechToText.initialize(
        onError: (e) => debugPrint('Speech Error: $e'),
        onStatus: (s) => debugPrint('Speech Status: $s'),
      );
      if (mounted) {
        setState(() {
          _speechEnabled = initialized;
        });
      }
    } catch (e) {
      debugPrint('STT Init gracefully caught error: $e');
      if (mounted) {
        setState(() {
          _speechEnabled = false;
        });
      }
    }
  }

  Future<void> _loadLevelData() async {
    // Pre-check: Ensure user has hearts to begin!
    final initialHearts = ref.read(gamificationControllerProvider).valueOrNull?.userProfile.hearts ?? 0;
    if (initialHearts <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
         _showRefillPrompt();
      });
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final fetched = await ref.read(quranApiServiceProvider).getAyahRange(
        widget.level.surahId,
        widget.level.ayahStart,
        widget.level.ayahEnd,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final savedIdx = prefs.getInt('voice_prog_${widget.level.id}') ?? 0;
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

    final String fullText = _ayahs[_currentAyahIndex].text.replaceAll(RegExp(r'\s+'), ' ').trim();
    _targetWords = fullText.split(' ');
    _wordStatuses = List.generate(_targetWords.length, (_) => WordStatus.pending);
    _wordsSpoken = "";
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً، ميزة التعرف على الكلام غير مفعلة')),
      );
      return;
    }

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'ar-SA', // Prioritize Arabic
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );

    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });

    if (result.finalResult) {
      _processFinalSpeech(_wordsSpoken);
    }
  }

  void _processFinalSpeech(String rawText) {
    if (rawText.isEmpty) return;

    final normalizedSpokenText = _normalizeArabic(rawText);
    final spokenWords = normalizedSpokenText.split(' ').where((w) => w.isNotEmpty).toList();
    
    setState(() {
      _isListening = false; // Automatically stop indicator
      
      // 🎯 Global Match Logic:
      int correctCount = 0;
      
      for (int i = 0; i < _targetWords.length; i++) {
        final target = _normalizeArabic(_targetWords[i]);
        if (target.isEmpty) continue;

        bool matched = false;
        
        for (var s in spokenWords) {
          // Exact or Contains Check first
          if (s == target || target.contains(s) || s.contains(target)) {
            matched = true;
            break;
          }
          // Ultra-Relaxed Character Overlap (Fuzzy Matching):
          if (_calculateCharacterOverlap(s, target) >= 0.6) {
            matched = true;
            break;
          }
        }
        
        if (matched) {
          _wordStatuses[i] = WordStatus.correct;
          correctCount++;
        } else {
          _wordStatuses[i] = WordStatus.incorrect;
        }
      }

      // 🔥 Lowered to 65% threshold for extreme flexibility as requested!
      final double successRatio = correctCount / _targetWords.length;
      
      if (successRatio >= 0.65) {
        // Success!
        for (int i = 0; i < _wordStatuses.length; i++) {
          _wordStatuses[i] = WordStatus.correct;
        }
        _onAyahCompleted();
      } else {
        // Failure: Deduct heart and alert user.
        _deductHeart();
      }
    });
  }

  void _onAyahCompleted() async {
    await _stopListening();
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (_currentAyahIndex < _ayahs.length - 1) {
        setState(() {
          _currentAyahIndex++;
          _setupCurrentAyah();
        });
        // Save locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('voice_prog_${widget.level.id}', _currentAyahIndex);
      } else {
        await _finishLevel();
      }
    });
  }

  Future<void> _finishLevel() async {
    await ref.read(gamificationControllerProvider.notifier)
        .completeSubTask(widget.level.id, 'quiz'); // Mapping it to existing quiz tracker logically
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ما شاء الله!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 60, color: Colors.green),
            SizedBox(height: 16),
            Text('لقد أتممت القراءة الصوتية بنجاح!', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss Dialog
              Navigator.of(context).pop(); // Return to Home
            },
            child: const Text('حسناً'),
          )
        ],
      ),
    );
  }

  // Normalize to plain Arabic for comparison
  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]'), '') // Clear Tashkeel AND Quranic Punctuation Marks
        .replaceAll(RegExp(r'[إأآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '') // Remove ANY other non-letter symbol
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  // Super-relaxed logic: checks percentage of characters from target present in the spoken word
  double _calculateCharacterOverlap(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final chars1 = s1.split('');
    final chars2 = s2.split('');
    
    int matchedCount = 0;
    List<String> availableChars = List.from(chars2);

    for (var char in chars1) {
      if (availableChars.contains(char)) {
        matchedCount++;
        availableChars.remove(char); // Consume once
      }
    }

    // Overlap ration relative to shortest word to ensure flexibility
    final int minLen = chars1.length < chars2.length ? chars1.length : chars2.length;
    if (minLen == 0) return 0.0;
    
    return matchedCount / minLen;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) return const Scaffold(body: LoadingWidget());
    if (_error != null) return Scaffold(body: Center(child: Text('خطأ: $_error')));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFDFBF7),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text('القراءة والتحقق الصوتي', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildHeartsRow(),
            )
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(
                  value: _ayahs.isEmpty ? 0 : (_currentAyahIndex / _ayahs.length),
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isListening ? Colors.blue : Colors.transparent, 
                        width: 2
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening 
                            ? Colors.blue.withValues(alpha: 0.2) 
                            : Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: 2
                        )
                      ]
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(_targetWords.length, (i) {
                          final status = _wordStatuses[i];

                          Color textColor = isDark ? Colors.white70 : Colors.black87;
                          Color bgColor = Colors.transparent;

                          if (status == WordStatus.correct) {
                            textColor = Colors.green.shade700;
                            bgColor = Colors.green.shade50;
                          } else if (status == WordStatus.incorrect) {
                            textColor = Colors.red.shade700;
                            bgColor = Colors.red.shade50;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _targetWords[i],
                              style: TextStyle(
                                fontSize: 24,
                                fontFamily: 'KFGQPC Uthmanic Script',
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ).animate(target: status != WordStatus.pending ? 1 : 0).scale(duration: 300.ms, curve: Curves.easeOut);
                        }),
                      ),
                    ),
                  ),
                ),
              ),

              // Dynamic Spoken Text Buffer Visualization
              if (_wordsSpoken.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _wordsSpoken,
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),

              // Control Area
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      _isListening ? "استمع إليك الآن..." : "اضغط على الميكروفون وابدأ القراءة",
                      style: TextStyle(
                        color: _isListening ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening)
                            const SizedBox(
                              width: 90,
                              height: 90,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: _isListening ? Colors.green : Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.green : Colors.blue).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_speechEnabled)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('الميكروفون غير متاح أو غير مدعوم', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartsRow() {
    final asyncState = ref.watch(gamificationControllerProvider);
    final profile = asyncState.valueOrNull?.userProfile;
    
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: HeartTimerDisplay(
        profile: profile,
        fontSize: 14,
      ),
    );
  }

  // ❤️ HEARTS MANAGEMENT
  Future<void> _deductHeart() async {
    final controller = ref.read(gamificationControllerProvider.notifier);
    await controller.loseHeart();
    
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('توجد أخطاء في القراءة! تم خصم محاولة 💔', textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      
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
}

enum WordStatus { pending, correct, incorrect }
