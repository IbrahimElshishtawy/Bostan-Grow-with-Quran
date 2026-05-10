import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'dart:math' as math;

class WriteGameplayScreen extends ConsumerStatefulWidget {
  final GameLevel level;

  const WriteGameplayScreen({super.key, required this.level});

  @override
  ConsumerState<WriteGameplayScreen> createState() => _WriteGameplayScreenState();
}

class _WriteGameplayScreenState extends ConsumerState<WriteGameplayScreen> {
  int _hearts = 3; // User has 3 in-game lives for the challenge
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
    try {
      final fetched = await ref.read(quranApiServiceProvider).getAyahRange(
        widget.level.surahId,
        widget.level.ayahStart,
        widget.level.ayahEnd,
      );
      if (mounted) {
        setState(() {
          _ayahs = fetched;
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

  void _deductHeart() {
    setState(() {
      _hearts--;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('خطأ! انتبه للكلمة التالية ❌', textAlign: TextAlign.center),
        backgroundColor: Colors.redAccent,
        duration: Duration(milliseconds: 600),
      ),
    );

    if (_hearts <= 0) {
      _showRefillPrompt();
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
            onPressed: () {
              Navigator.pop(c);
              setState(() {
                _hearts = 3; // Simulate Ad reward instantly!
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
            label: const Text('مشاهدة إعلان لاستعادة المحاولات 🎁', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _advanceToNextAyah() {
    if (_currentAyahIndex < _ayahs.length - 1) {
      setState(() {
        _currentAyahIndex++;
        _setupCurrentAyah();
      });
    } else {
      // COMPLETION!
      setState(() {
         _currentAyahIndex++; // flag complete
      });
      ref.read(gamificationControllerProvider.notifier).completeSubTask(widget.level.id, 'write');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _currentAyahIndex >= _ayahs.length && _ayahs.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          title: const Text('تحدي بناء وتركيب الآيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            // HEARTS ROW!
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, color: _hearts > 0 ? Colors.redAccent : Colors.grey[400], size: 18),
                  const SizedBox(width: 4),
                  Text('$_hearts', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: GameificationColors.primaryGreen))
            : _error != null
                ? Center(child: Text('خطأ: $_error'))
                : isDone 
                    ? _buildWinState()
                    : _buildGameplayLayout(),
      ),
    );
  }

  Widget _buildGameplayLayout() {
    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: _currentAyahIndex / _ayahs.length,
          backgroundColor: Colors.grey[200],
          color: GameificationColors.primaryGreen,
          minHeight: 6,
        ),
        
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'الآية ${_currentAyahIndex + 1} من ${_ayahs.length}',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, spreadRadius: 2),
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
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey, size: 16),
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
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
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
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        word,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
