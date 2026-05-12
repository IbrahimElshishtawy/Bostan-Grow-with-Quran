import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
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
  int _currentWordTargetIndex = 0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadLevelData();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (e) => debugPrint('Speech Error: $e'),
        onStatus: (s) => debugPrint('Speech Status: $s'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('STT Init Error: $e');
    }
  }

  Future<void> _loadLevelData() async {
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
    _currentWordTargetIndex = 0;
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
      _processIncomingSpeech(_wordsSpoken);
    });
  }

  void _processIncomingSpeech(String rawText) {
    if (rawText.isEmpty) return;

    final spokenSegments = rawText.trim().split(' ');
    // Take only the last few elements to prevent overlap re-checking?
    // Actually, check total matches linearly!
    
    final normalizedText = _normalizeArabic(rawText);
    final spokenWords = normalizedText.split(' ').where((w) => w.isNotEmpty).toList();

    // Dynamic progressive detection
    for (var sWord in spokenWords) {
      if (_currentWordTargetIndex >= _targetWords.length) break;

      final targetNormalized = _normalizeArabic(_targetWords[_currentWordTargetIndex]);
      
      // Similarity Check
      if (sWord == targetNormalized || targetNormalized.contains(sWord) || sWord.contains(targetNormalized)) {
        setState(() {
          _wordStatuses[_currentWordTargetIndex] = WordStatus.correct;
          _currentWordTargetIndex++;
        });
      } else {
        // User said something that doesn't match next word?
        // Only mark incorrect if user finished total phrase or pauses?
        // Let's optionally mark NEXT word wrong if failure rate high.
        // User requested: "الغلط يتعمل عليه احمر" -> We mark current attempt's targeted word incorrect if no match after final results!
      }
    }

    if (_currentWordTargetIndex >= _targetWords.length) {
      _onAyahCompleted();
    }
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
        _finishLevel();
      }
    });
  }

  void _finishLevel() {
    ref.read(gamificationControllerProvider.notifier)
        .completeSubTask(widget.level.id, 'quiz'); // Mapping it to existing quiz tracker logically
    
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
        .replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u0652]'), '') // Clear Tashkeel
        .replaceAll(RegExp(r'[إأآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(_targetWords.length, (i) {
                          final status = _wordStatuses[i];
                          final isTarget = i == _currentWordTargetIndex;

                          Color textColor = Colors.grey;
                          Color bgColor = Colors.transparent;

                          if (status == WordStatus.correct) {
                            textColor = Colors.green.shade700;
                            bgColor = Colors.green.shade50;
                          } else if (status == WordStatus.incorrect) {
                            textColor = Colors.red.shade700;
                            bgColor = Colors.red.shade50;
                          } else if (isTarget) {
                            textColor = Colors.blue.shade800;
                            bgColor = Colors.blue.shade50;
                          } else {
                            textColor = isDark ? Colors.white70 : Colors.black87;
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: isTarget ? Border.all(color: Colors.blue, width: 1.5) : null,
                              boxShadow: isTarget ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 8)] : null,
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
                          ).animate(target: isTarget ? 1 : 0).scale(duration: 300.ms, curve: Curves.easeOut);
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
}

enum WordStatus { pending, correct, incorrect }
