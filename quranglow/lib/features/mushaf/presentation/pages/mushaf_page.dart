import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/features/mushaf/presentation/pages/paged_mushaf.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/ayah_actions_sheet.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/mushaf_top_bar.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/position_store.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/selected_ayah_panel.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_args.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';
import 'package:quranglow/core/widgets/shimmer_loading.dart';

final surahProvider = FutureProvider.autoDispose
    .family<Surah, (int chapter, String editionId)>((ref, args) async {
      final service = ref.read(quranServiceProvider);
      return service.getSurahText(args.$2, args.$1);
    });

class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({
    super.key,
    this.chapter = 1,
    this.editionId = 'quran-uthmani',
    this.initialAyah,
  });

  final int chapter;
  final String editionId;
  final int? initialAyah;

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  bool _uiVisible = false;
  late int _chapter;
  int? _lastAyahNumber;
  bool _trackingSessionStarted = false;
  late final dynamic _trackingService;
  DateTime? _listeningStartedAt;
  StreamSubscription? _ayahPlayerSub;

  final _pos = PositionStore();
  final _ayahPreviewPlayer = AudioPlayer();
  final GlobalKey<PagedMushafState> _pagedMushafKey =
      GlobalKey<PagedMushafState>();

  // 🎙️ Hifz Voice Recitation Mode State
  bool _voiceReciteMode = false;
  final Map<int, Set<int>> _revealedWords = {}; // Surah Ayah Number -> Set of word indices
  final Map<int, Set<int>> _mistakenWords = {}; // Surah Ayah Number -> Set of wrong/skipped word indices
  int _consumedSpokenWordsCount = 0; // Tracker for real-time session stream offsets
  bool _speechEnabled = false;
  bool _isListening = false;
  String _wordsSpoken = "";
  bool _matchedAnyWordsThisSession = false; // 🎯 Tracks if at least 1 word was matched during current microphone active session
  final SpeechToText _speechToText = SpeechToText();

  @override
  void initState() {
    super.initState();
    _trackingService = ref.read(trackingServiceProvider);
    _chapter = widget.chapter.clamp(1, 114);
    _lastAyahNumber = widget.initialAyah;
    
    // Initialize Hifz Speech Recognition
    _initSpeech();

    // Track listening time for Mushaf preview audio
    _ayahPlayerSub = _ayahPreviewPlayer.playingStream.listen((playing) {
      _trackListeningState(playing);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await WakelockPlus.enable();
      if (!mounted) return;
      await _trackingService.startSession();
      if (!mounted) return;
      _trackingSessionStarted = true;
    });
  }

  @override
  void dispose() {
    _flushListeningTime();
    if (_trackingSessionStarted) {
      _trackingService.endSession();
    }
    _ayahPlayerSub?.cancel();
    _ayahPreviewPlayer.dispose();
    _speechToText.stop(); // Safely stop listening on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WakelockPlus.disable();
    super.dispose();
  }

  void _trackListeningState(bool isPlaying) {
    if (isPlaying) {
      _listeningStartedAt ??= DateTime.now();
      return;
    }
    _flushListeningTime();
  }

  void _flushListeningTime() {
    final startedAt = _listeningStartedAt;
    if (startedAt == null) return;
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    _listeningStartedAt = null;
    if (seconds > 0) {
      _trackingService.addListeningTime(seconds);
    }
  }

  String _audioEditionId() {
    final settings = ref.read(settingsProvider);
    return settings.maybeWhen(
      data: (s) {
        final editionId = s.readerEditionId.trim();
        return editionId.isEmpty ? 'ar.alafasy' : editionId;
      },
      orElse: () => 'ar.alafasy',
    );
  }

  void _goPrev() {
    if (_chapter <= 1) return;
    setState(() {
      _chapter--;
      _lastAyahNumber = null;
    });
    _pagedMushafKey.currentState?.animateToPage(0);
  }

  void _goNext() {
    if (_chapter >= 114) return;
    setState(() {
      _chapter++;
      _lastAyahNumber = null;
    });
    _pagedMushafKey.currentState?.animateToPage(0);
  }

  Future<void> _saveCurrentPosition() async {
    final ayahIndex0 = (_lastAyahNumber ?? 1) - 1;
    await _pos.save(_chapter, ayahIndex0);
    // Force visual UI update of the ribbon marker immediately
    _pagedMushafKey.currentState?.forceRefreshBookmark(ayahIndex0);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ موضع القراءة')));
  }

  void _openTafsirForAyah(int ayahNumber) {
    Navigator.pushNamed(
      context,
      AppRoutes.tafsirReader,
      arguments: TafsirArgs(chapter: _chapter, ayah: ayahNumber),
    );
  }

  void _copyAyahText(int ayahNumber, String ayahText) {
    final content = '$_chapter:$ayahNumber\n$ayahText';
    Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الآية')));
  }

  Future<void> _playAyahAudio(Aya aya, int ayahNumber) async {
    final isActuallyPlaying = _ayahPreviewPlayer.playing &&
        _ayahPreviewPlayer.processingState != ProcessingState.completed;
        
    if (isActuallyPlaying) {
      await _ayahPreviewPlayer.stop();
      return;
    }
    try {
      String? url = aya.audioUrl;
      if (url == null || url.trim().isEmpty) {
        final service = ref.read(quranServiceProvider);
        final audioMap = await service.getSurahAudioUrlMap(
          _audioEditionId(),
          _chapter,
        );
        url = audioMap[ayahNumber];

        if (url == null || url.trim().isEmpty) {
          final urls = await service.getSurahAudioUrls(
            _audioEditionId(),
            _chapter,
          );
          final idx = ayahNumber - 1;
          if (idx >= 0 && idx < urls.length) {
            url = urls[idx];
          }
        }
      }

      if (url == null || url.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد ملف صوت متاح لهذه الآية')),
        );
        return;
      }

      await _ayahPreviewPlayer.setUrl(url);
      await _ayahPreviewPlayer.play();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يتم تشغيل الآية $ayahNumber'),
          duration: const Duration(seconds: 1),
        ),
      );
    } on PlayerInterruptedException {
      // 🤫 User tapped another Ayah before the previous one finished loading!
      // This is perfectly expected, so we stay completely silent.
      debugPrint('Audio loading was interrupted by user action (swapping tracks).');
    } on PlayerException catch (e) {
      // A real just_audio error (network fail, source not found etc.)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في مشغل الصوت: ${e.message}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تشغيل الآية: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openAyahActions({
    required int ayahNumber,
    required List<Aya> ayat,
  }) async {
    setState(() {
      _lastAyahNumber = ayahNumber;
      _uiVisible = true;
    });

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AyahActionsSheet(
        ayat: ayat,
        initialAyahNumber: ayahNumber,
        onAyahChanged: (nextAyahNumber) {
          setState(() => _lastAyahNumber = nextAyahNumber);
        },
        onPlayAyah: _playAyahAudio,
        onOpenTafsir: (currentAyahNumber) {
          Navigator.pop(ctx);
          _openTafsirForAyah(currentAyahNumber);
        },
        onCopyAyah: _copyAyahText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSurah = ref.watch(surahProvider((_chapter, widget.editionId)));
    final selectedAyahText = asyncSurah.maybeWhen(
      data: (surah) {
        final selected = _lastAyahNumber;
        if (selected == null) return null;
        final idx = selected - 1;
        if (idx < 0 || idx >= surah.ayat.length) return null;
        return surah.ayat[idx].text;
      },
      orElse: () => null,
    );



    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark 
        ? const [Color(0xFF18140E), Color(0xFF0D0B08)] 
        : const [Color(0xFFFFFDF8), Color(0xFFFDF7E8)];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgGradient,
            ),
          ),
          child: Stack(
            children: [
              // 1. Subtle Subconscious Islamic Pattern Texture
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.05 : 0.03, // Extremely subtle as requested
                  child: Image.asset(
                    'assets/images/islamic_pattern.png',
                    repeat: ImageRepeat.repeat,
                    width: 220, // Controlled scale for elegance
                    height: 220,
                    color: isDark ? Colors.white : const Color(0xFF8B6D3A),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),
              asyncSurah.when(
                loading: () => const MushafSkeleton(),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل السورة'),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.refresh(
                            surahProvider((_chapter, widget.editionId)),
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (surah) => PagedMushaf(
                  key: _pagedMushafKey,
                  ayat: surah.ayat,
                  surahName: surah.name,
                  surahNumber: _chapter,
                  showBasmala: surah.name.trim() != 'التوبة',
                  initialSelectedAyah: _lastAyahNumber,
                  onAyahTap: (int ayahNumber, Aya aya) {
                    setState(() {
                      _lastAyahNumber = ayahNumber;
                      _uiVisible = true;
                    });
                    _trackingService.incAyat(1);
                  },
                  onAyahLongPress: (int ayahNumber, Aya aya) {
                    _openAyahActions(
                      ayahNumber: ayahNumber,
                      ayat: surah.ayat,
                    );
                  },
                  onVisiblePageChanged: (n) => _lastAyahNumber = n,
                  onBackgroundTap: () => setState(() => _uiVisible = !_uiVisible),
                  isHifzMode: _voiceReciteMode,
                  revealedWords: _revealedWords,
                  mistakenWords: _mistakenWords,
                ),
              ),

              MushafTopBar(
                visible: _uiVisible,
                asyncSurah: asyncSurah,
                chapter: _chapter,
                onBack: () => Navigator.pop(context),
                onPrev: _chapter > 1 ? _goPrev : null,
                onNext: _chapter < 114 ? _goNext : null,
                onSave: _saveCurrentPosition,
                onTafsir: () => _openTafsirForAyah(_lastAyahNumber ?? 1),
                onVoiceRecite: () {
                  setState(() {
                    _voiceReciteMode = !_voiceReciteMode;
                    _revealedWords.clear();
                    _mistakenWords.clear();
                    _consumedSpokenWordsCount = 0;
                    _wordsSpoken = "";
                    _uiVisible = false; // Hide standard UI to focus on Hifz
                  });
                  
                  if (_voiceReciteMode) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'تم تفعيل وضع التسميع! 🎙️ الكلمات مخفية الآن. اضغط على زر الميكروفون أدناه وابدأ القراءة لتكشف الآيات.',
                          textAlign: TextAlign.center,
                        ),
                        backgroundColor: Colors.amber.shade800,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                },
              ),
              StreamBuilder<PlayerState>(
                stream: _ayahPreviewPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final isPlaying = (state?.playing ?? false) &&
                      (state?.processingState != ProcessingState.completed);
                  return SelectedAyahPanel(
                    visible: _lastAyahNumber != null && selectedAyahText != null && !_voiceReciteMode,
                    ayahNumber: _lastAyahNumber,
                    ayahText: selectedAyahText,
                    isPlaying: isPlaying,
                    onClear: () {
                      _ayahPreviewPlayer.stop(); // Stop if user clears panel
                      setState(() => _lastAyahNumber = null);
                    },
                    onOpenTafsir: () => _openTafsirForAyah(_lastAyahNumber ?? 1),
                    onPlay: () {
                      final ayahNum = _lastAyahNumber;
                      final surah = asyncSurah.valueOrNull;
                      if (ayahNum == null || surah == null) return;
                      final idx = ayahNum - 1;
                      if (idx < 0 || idx >= surah.ayat.length) return;
                      _playAyahAudio(surah.ayat[idx], ayahNum);
                    },
                    onCopy: () {
                      final text = selectedAyahText;
                      final ayahNum = _lastAyahNumber;
                      if (text == null || ayahNum == null) return;
                      _copyAyahText(ayahNum, text);
                    },
                    onSave: _saveCurrentPosition,
                  );
                },
              ),

              // 🎤 8. Floating Hifz Recitation Overlay!
              _buildHifzVoiceOverlay(asyncSurah.valueOrNull),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── 🎙️ HIFZ VOICE SYSTEM LOGIC ───────────────────

  Future<void> _initSpeech() async {
    try {
      final initialized = await _speechToText.initialize(
        onError: (e) => debugPrint('Hifz Speech Error: $e'),
        onStatus: (s) {
          debugPrint('Hifz Speech Status: $s');
          if (_voiceReciteMode && (s == 'notListening' || s == 'done')) {
            _handleSessionEnd();
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechEnabled = initialized;
        });
      }
    } catch (e) {
      debugPrint('Hifz STT Init Error: $e');
    }
  }

  void _handleSessionEnd() {
    if (!mounted || !_voiceReciteMode) return;

    final asyncSurah = ref.read(surahProvider((_chapter, "quran-uthmani")));
    final surah = asyncSurah.valueOrNull;
    if (surah == null) return;

    // 1. Find current active target ayah
    int targetIndex = -1;
    int pageStartNum = _lastAyahNumber ?? 1;
    for (int i = 0; i < surah.ayat.length; i++) {
      final a = surah.ayat[i];
      final totalWords = a.text.trim().split(RegExp(r'\s+')).length;
      final revealedCount = _revealedWords[a.numberInSurah]?.length ?? 0;
      if (a.numberInSurah >= pageStartNum && revealedCount < totalWords) {
        targetIndex = i;
        break;
      }
    }
    if (targetIndex == -1) {
      for (int i = 0; i < surah.ayat.length; i++) {
        final a = surah.ayat[i];
        final totalWords = a.text.trim().split(RegExp(r'\s+')).length;
        final revealedCount = _revealedWords[a.numberInSurah]?.length ?? 0;
        if (revealedCount < totalWords) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex == -1) return; // Completed

    final targetAyah = surah.ayat[targetIndex];
    final totalWordCount = targetAyah.text.trim().split(RegExp(r'\s+')).length;

    // 2. Inspect spoken text
    final normalized = _normalizeArabic(_wordsSpoken);
    final spokenWords = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    final int spokenCount = spokenWords.length;

    // 🛑 TOTAL FAILURE HEURISTIC: 3+ words spoken with ZERO matches
    if (spokenCount >= 3 && !_matchedAnyWordsThisSession) {
      HapticFeedback.heavyImpact();

      final Set<int> oldRevealed = _revealedWords[targetAyah.numberInSurah] ?? {};
      final Set<int> missedIndices = {};
      for (int wIdx = 0; wIdx < totalWordCount; wIdx++) {
        if (!oldRevealed.contains(wIdx)) {
          missedIndices.add(wIdx);
        }
      }

      setState(() {
        if (missedIndices.isNotEmpty) {
          _mistakenWords[targetAyah.numberInSurah] = missedIndices;
        }
        final allWordIndices = Set<int>.from(Iterable<int>.generate(totalWordCount));
        _revealedWords[targetAyah.numberInSurah] = allWordIndices;
        _isListening = false; // Force UI reflect STOPPED
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkPageCompletion(surah.ayat);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ قراءة غير مطابقة تماماً! تم إيقاف التسجيل للمراجعة والتصحيح.', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return; // 🛑 ABORT LOOP! RECORDING STOPS HERE
    }

    // 🔄 Otherwise, normal auto-resume loop for standard pauses
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _voiceReciteMode && !_isListening) {
        _startListening();
      }
    });
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الميكروفون غير مفعل أو مقيد! يرجى إعطاء الصلاحيات.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'ar-SA',
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 6),
      partialResults: true,
      listenMode: ListenMode.dictation, // 🎙️ Ultra-Optimized for continuous long-form dictation/recitation!
      cancelOnError: false, // 🛑 Robust: remain active even on temporary network interruptions!
    );

    setState(() {
      _isListening = true;
      _wordsSpoken = "";
      _matchedAnyWordsThisSession = false; // 📍 Reset matching flag on fresh start
      _consumedSpokenWordsCount = 0; // 📍 Reset stream consumer counter on fresh session
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!_isListening) return; // Event loop safety guard
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });

    _processSpeechResult(result.recognizedWords, isFinal: result.finalResult);
  }

  void _processSpeechResult(String spokenText, {required bool isFinal}) {
    if (spokenText.trim().isEmpty) return;
    
    final asyncSurah = ref.read(surahProvider((_chapter, widget.editionId)));
    final surah = asyncSurah.valueOrNull;
    if (surah == null) return;

    // 1. Determine active page boundaries to restrict Hifz to the CURRENT PAGE only!
    final state = _pagedMushafKey.currentState;
    final pageRange = state?.getCurrentPageRange();
    
    int searchStartIdx = 0;
    int searchEndIdx = surah.ayat.length;
    if (pageRange != null) {
      searchStartIdx = pageRange.start;
      searchEndIdx = pageRange.end;
    }

    // Find the target incomplete ayah strictly WITHIN the current page bounds!
    int targetIndex = -1;
    for (int i = searchStartIdx; i < searchEndIdx; i++) {
      final a = surah.ayat[i];
      final totalWords = a.text.trim().split(RegExp(r'\s+')).length;
      final revealedCount = _revealedWords[a.numberInSurah]?.length ?? 0;
      if (revealedCount < totalWords) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex == -1) return; // 🔥 End of Page Reached or Page Completely Revealed!

    final targetAyah = surah.ayat[targetIndex];
    final targetWords = targetAyah.text.trim().split(RegExp(r'\s+'));
    final totalWordCount = targetWords.length;
    
    // 2. Extract ONLY unconsumed spoken words since last milestone
    final normalizedSpoken = _normalizeArabic(spokenText);
    final allSpokenWords = normalizedSpoken.split(' ').where((w) => w.isNotEmpty).toList();
    
    if (allSpokenWords.length <= _consumedSpokenWordsCount) return;
    final newSpokenWords = allSpokenWords.sublist(_consumedSpokenWordsCount);

    // 🚀 INTELLIGENT SKIP DETECTION: Restricted only to the bounds of the current page!
    if (targetIndex + 1 < searchEndIdx) {
      final nextAyah = surah.ayat[targetIndex + 1];
      final nextWords = nextAyah.text.trim().split(RegExp(r'\s+'));
      int nextMatches = 0;
      final checkLen = nextWords.length < 3 ? nextWords.length : 3;
      
      for (int k = 0; k < checkLen; k++) {
        final ntw = _normalizeArabic(nextWords[k]);
        if (ntw.isEmpty) continue;
        for (final sw in newSpokenWords) {
          if (sw == ntw) {
            nextMatches++;
            break;
          }
          final swNoAlif = sw.replaceAll(RegExp(r'[اأإآ]'), '');
          final ntwNoAlif = ntw.replaceAll(RegExp(r'[اأإآ]'), '');
          if (swNoAlif.isNotEmpty && swNoAlif == ntwNoAlif) {
            nextMatches++;
            break;
          }
        }
      }

      final bool hasSkippedCurrent = (checkLen >= 2 && nextMatches >= 2) || (checkLen < 2 && nextMatches >= 1);
      
      if (hasSkippedCurrent) {
        // 🛑 ABANDON CURRENT AYAH: Reveal all remaining words as MISTAKES in Red!
        final Set<int> oldRevealed = _revealedWords[targetAyah.numberInSurah] ?? {};
        final Set<int> missedIndices = {};
        for (int wIdx = 0; wIdx < totalWordCount; wIdx++) {
          if (!oldRevealed.contains(wIdx)) {
            missedIndices.add(wIdx);
          }
        }

        HapticFeedback.heavyImpact();
        setState(() {
          if (missedIndices.isNotEmpty) {
            _mistakenWords[targetAyah.numberInSurah] = missedIndices;
          }
          final allWordIndices = Set<int>.from(Iterable<int>.generate(totalWordCount));
          _revealedWords[targetAyah.numberInSurah] = allWordIndices;
        });

        // Check if this skip triggers full page completion!
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _checkPageCompletion(surah.ayat);
        });
        
        // Flush listener and restart. In the next frame, targetIndex will evaluate to targetIndex + 1,
        // and those very same spoken words will be processed against it instantly!
        _stopListening();
        return;
      }
    }

    Set<int> currentRevealed = _revealedWords[targetAyah.numberInSurah] ?? {};
    // 3. 🔒 Sequential Reveal Lock: Only check a lookahead window of 3 words from current position
    int firstUnrevealedIdx = totalWordCount;
    for (int wIdx = 0; wIdx < totalWordCount; wIdx++) {
      if (!currentRevealed.contains(wIdx)) {
        firstUnrevealedIdx = wIdx;
        break;
      }
    }

    bool stateUpdated = false;
    final maxCheckIdx = (firstUnrevealedIdx + 3).clamp(0, totalWordCount);

    for (int wIdx = firstUnrevealedIdx; wIdx < maxCheckIdx; wIdx++) {
      final tw = _normalizeArabic(targetWords[wIdx]);
      if (tw.isEmpty) continue;

      bool wordMatched = false;
      for (final sw in newSpokenWords) {
        // 🎯 TIGHT MATCHING: Exact equality first
        if (sw == tw) {
          wordMatched = true;
          break;
        }
        // 🎯 ALIF-STRIPPED FALLBACK: Handles Uthmani vs Modern Alif variances (e.g. ملك vs مالك, السموت vs السماوات)
        final swNoAlif = sw.replaceAll(RegExp(r'[اأإآ]'), '');
        final twNoAlif = tw.replaceAll(RegExp(r'[اأإآ]'), '');
        if (swNoAlif.isNotEmpty && swNoAlif == twNoAlif) {
          wordMatched = true;
          break;
        }
        // 🎯 TIGHT OVERLAP: Only for longer words (>3 chars), require 75%+ similarity
        if (sw.length > 3 && tw.length > 3 && _calculateOverlap(sw, tw) >= 0.75) {
          wordMatched = true;
          break;
        }
      }

      if (wordMatched) {
        if (!stateUpdated) {
          currentRevealed = Set.from(currentRevealed);
          stateUpdated = true;
        }
        currentRevealed.add(wIdx);
      }
    }

    if (stateUpdated) {
      HapticFeedback.selectionClick();
      _matchedAnyWordsThisSession = true; // 🎯 TRIPPED: Actually matched something!
      setState(() {
        _revealedWords[targetAyah.numberInSurah] = currentRevealed;
      });
    }

    // 4. 🔥 Evaluate ayah completion with user-requested 70% threshold!
    final double completionRatio = currentRevealed.length / totalWordCount;
    if (completionRatio >= 0.70) {
      HapticFeedback.heavyImpact();
      
      // 🛑 IDENTIFY MISTAKES: Find any word indices that were NOT completed before triggering 70% autocomplete!
      final Set<int> missedIndices = {};
      for (int wIdx = 0; wIdx < totalWordCount; wIdx++) {
        if (!currentRevealed.contains(wIdx)) {
          missedIndices.add(wIdx);
        }
      }

      setState(() {
        // Track the mistakes for Red-coloring
        if (missedIndices.isNotEmpty) {
          _mistakenWords[targetAyah.numberInSurah] = missedIndices;
        }

        // Auto-reveal the entire remaining words of this ayah (missed ones will render in Red!)
        final allWordIndices = Set<int>.from(Iterable<int>.generate(totalWordCount));
        _revealedWords[targetAyah.numberInSurah] = allWordIndices;
        
        // 🎯 Transition: consume all spoken words to ignore them when checking next ayah!
        _consumedSpokenWordsCount = allSpokenWords.length;
      });

      // 🏆 CRITICAL EVENT: Fire a check to see if this completions crowns the entire visible page!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkPageCompletion(surah.ayat);
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('أحسنت! اكتملت الآية رقم ${targetAyah.numberInSurah} (التقييم: ${(completionRatio * 100).toInt()}%) 🎉'),
          backgroundColor: Colors.teal.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1200),
        ),
      );

      // 🚨 BUFFER FLUSH: Stop the listener to clear all accumulated audio stream cache.
      // The onStatus loop will automatically start a completely sterile and fresh session in 500ms!
      _stopListening();
    }
  }

  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'), '') 
        .replaceAll(RegExp(r'[إأآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^\u0621-\u064A\s]'), '') 
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }

  double _calculateOverlap(String s1, String s2) {
    final chars1 = s1.split('');
    final chars2 = s2.split('');
    int matchedCount = 0;
    final available = List.from(chars2);
    for (var c in chars1) {
      if (available.contains(c)) {
        matchedCount++;
        available.remove(c);
      }
    }
    final int minLen = chars1.length < chars2.length ? chars1.length : chars2.length;
    if (minLen == 0) return 0.0;
    return matchedCount / minLen;
  }

  Widget _buildHifzVoiceOverlay(Surah? surah) {
    if (!_voiceReciteMode) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int targetNum = 1;
    if (surah != null) {
      int pageStartNum = _lastAyahNumber ?? 1;
      for (final a in surah.ayat) {
        final totalWords = a.text.trim().split(RegExp(r'\s+')).length;
        final revealedCount = _revealedWords[a.numberInSurah]?.length ?? 0;
        if (a.numberInSurah >= pageStartNum && revealedCount < totalWords) {
          targetNum = a.numberInSurah;
          break;
        }
      }
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: 30,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xEE1E1E1E) : const Color(0xEEFFFFFF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              spreadRadius: 5,
            )
          ],
          border: Border.all(
            color: _isListening ? Colors.teal.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  tooltip: 'إغلاق وضع التسميع',
                  onPressed: () {
                    _stopListening();
                    setState(() {
                      _voiceReciteMode = false;
                      _revealedWords.clear();
                      _mistakenWords.clear();
                      _consumedSpokenWordsCount = 0;
                    });
                  },
                ),
                Text(
                  'التسميع الصوتي: الآية التالية ($targetNum)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Tajawal',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  tooltip: 'إعادة تسميع الصفحة',
                  onPressed: () {
                    setState(() {
                      _revealedWords.clear();
                      _mistakenWords.clear();
                      _consumedSpokenWordsCount = 0;
                      _wordsSpoken = "";
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            if (_isListening || _wordsSpoken.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _wordsSpoken.isEmpty ? 'جاري الاستماع الآن...' : _wordsSpoken,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: _wordsSpoken.isEmpty ? Colors.grey : Colors.amber.shade800,
                    fontSize: 15,
                  ),
                ),
              ),

            if (_isListening)
              GestureDetector(
                onTap: _stopListening,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 36),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.15, duration: 800.ms, curve: Curves.easeInOut)
                .shimmer(color: Colors.white24, duration: 1600.ms),
              )
            else
              GestureDetector(
                onTap: _startListening,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_none, color: Colors.white, size: 36),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _isListening ? 'اضغط للإيقاف أو التصحيح' : 'اضغط وابدأ القراءة بصوتك',
              style: TextStyle(
                color: _isListening ? Colors.redAccent : Colors.teal.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _checkPageCompletion(List<Aya> surahAyat) {
    final state = _pagedMushafKey.currentState;
    if (state == null) return;

    final pageRange = state.getCurrentPageRange();
    if (pageRange == null) return;

    bool pageFinished = true;
    for (int i = pageRange.start; i < pageRange.end; i++) {
      final a = surahAyat[i];
      final totalWords = a.text.trim().split(RegExp(r'\s+')).length;
      final revealed = _revealedWords[a.numberInSurah]?.length ?? 0;
      if (revealed < totalWords) {
        pageFinished = false;
        break;
      }
    }

    if (pageFinished) {
      HapticFeedback.vibrate();
      final pageAyat = surahAyat.sublist(pageRange.start, pageRange.end);
      _showHifzCompletionSummary(pageAyat);
    }
  }

  void _showHifzCompletionSummary(List<Aya> pageAyat) {
    int pageMistakesCount = 0;
    for (final a in pageAyat) {
      pageMistakesCount += _mistakenWords[a.numberInSurah]?.length ?? 0;
    }

    String motivationMsg;
    IconData icon;
    Color themeColor;
    if (pageMistakesCount == 0) {
      motivationMsg = "ما شاء الله تبارك الله! قراءة متقنة كالدر المنثور خالية تماماً من الأخطاء! 👑✨ ثبتك الله ورفع قدرك.";
      icon = Icons.stars_rounded;
      themeColor = Colors.amber.shade700;
    } else if (pageMistakesCount <= 3) {
      motivationMsg = "أداء رائع جداً ومبارك! وقعت في $pageMistakesCount أخطاء يسيرة جداً. كرر التسميع الآن لتصل لدرجة الإتقان الكامل! 💪🌟";
      icon = Icons.verified_rounded;
      themeColor = Colors.teal;
    } else {
      motivationMsg = "جهد رائع ومبارك! لديك $pageMistakesCount أخطاء. التكرار هو سر تمكين الحفظ وتثبيته، أعد التسميع بنشاط واستعن بالله! ❤️🌱";
      icon = Icons.menu_book_rounded;
      themeColor = Colors.blue.shade600;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade900.withValues(alpha: 0.95) 
              : Colors.white.withValues(alpha: 0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 70, color: themeColor).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  "تم بفضل الله!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "إتمام تسميع الصفحة بنجاح 🎉",
                  style: TextStyle(fontSize: 15, fontFamily: 'Tajawal', fontWeight: FontWeight.w500),
                ),
                const Divider(height: 30, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "عدد الأخطاء: ",
                      style: TextStyle(fontSize: 15, fontFamily: 'Tajawal'),
                    ),
                    Text(
                      "$pageMistakesCount",
                      style: TextStyle(
                        fontSize: 20, 
                        fontFamily: 'Tajawal', 
                        fontWeight: FontWeight.bold, 
                        color: pageMistakesCount > 0 ? Colors.redAccent.shade700 : Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: themeColor.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    motivationMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14, 
                      height: 1.6,
                      fontFamily: 'Tajawal', 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                        label: const Text("إعادة التسميع", style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _revealedWords.clear();
                            _mistakenWords.clear();
                            _consumedSpokenWordsCount = 0;
                            _wordsSpoken = "";
                          });
                          _startListening();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _voiceReciteMode = false;
                            _revealedWords.clear();
                            _mistakenWords.clear();
                          });
                        },
                        child: const Text("إغلاق", style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
