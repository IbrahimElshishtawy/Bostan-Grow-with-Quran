class Surah {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int verseCount;
  final String revelationType; // Makkiyah / Madaniyah
  final int startPage;
  final int endPage;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.verseCount,
    required this.revelationType,
    required this.startPage,
    required this.endPage,
  });

  bool get isMakkiyah => revelationType.toLowerCase().contains('makk');
}
