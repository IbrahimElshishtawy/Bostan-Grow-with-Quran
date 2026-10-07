import 'dart:math';
import 'package:quran/quran.dart' as quran;

class RevisionQuestion {
  final int surahNumber;
  final int givenAyahNumber;
  final String givenAyahText;
  final int correctNextAyahNumber;
  final String correctNextAyahText;
  final List<String> options;

  const RevisionQuestion({
    required this.surahNumber,
    required this.givenAyahNumber,
    required this.givenAyahText,
    required this.correctNextAyahNumber,
    required this.correctNextAyahText,
    required this.options,
  });
}

class RevisionEngine {
  RevisionEngine._();

  static RevisionQuestion generateNextAyahQuestion({
    required int surahNumber,
    required int startAyah,
    required int endAyah,
  }) {
    final rand = Random();
    final effectiveEnd = endAyah > startAyah ? endAyah - 1 : startAyah;
    final givenAyah = startAyah + rand.nextInt(effectiveEnd - startAyah + 1);
    final correctNextAyah = givenAyah + 1;

    final givenText = quran.getVerse(surahNumber, givenAyah);
    final correctNextText = quran.getVerse(surahNumber, correctNextAyah);

    // Pick 3 distractor verses from the same surah or nearby surahs
    final options = <String>[correctNextText];
    final totalVerses = quran.getVerseCount(surahNumber);

    while (options.length < 4) {
      final randomAyah = 1 + rand.nextInt(totalVerses);
      if (randomAyah != correctNextAyah && randomAyah != givenAyah) {
        final distractor = quran.getVerse(surahNumber, randomAyah);
        if (!options.contains(distractor)) {
          options.add(distractor);
        }
      }
      if (totalVerses <= 3) {
        // Fallback for short surahs: pick from Surah Al-Baqarah
        final fallback = quran.getVerse(2, 1 + rand.nextInt(20));
        if (!options.contains(fallback)) options.add(fallback);
      }
    }

    options.shuffle();

    return RevisionQuestion(
      surahNumber: surahNumber,
      givenAyahNumber: givenAyah,
      givenAyahText: givenText,
      correctNextAyahNumber: correctNextAyah,
      correctNextAyahText: correctNextText,
      options: options,
    );
  }

  static DateTime calculateNextRevisionDate({
    required bool isCorrect,
    required int currentStreak,
  }) {
    final now = DateTime.now();
    if (!isCorrect) {
      return now.add(const Duration(days: 1)); // Review tomorrow
    }
    // Spaced repetition intervals: 1 -> 3 -> 7 -> 14 -> 30 days
    final days = switch (currentStreak) {
      0 => 1,
      1 => 3,
      2 => 7,
      3 => 14,
      _ => 30,
    };
    return now.add(Duration(days: days));
  }
}
