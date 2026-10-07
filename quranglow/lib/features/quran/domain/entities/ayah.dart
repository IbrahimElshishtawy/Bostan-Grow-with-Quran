class Ayah {
  final int surahNumber;
  final int ayahNumber;
  final String textArabic;
  final int pageNumber;
  final int juzNumber;
  final bool isBookmarked;

  const Ayah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.textArabic,
    required this.pageNumber,
    required this.juzNumber,
    this.isBookmarked = false,
  });

  Ayah copyWith({
    int? surahNumber,
    int? ayahNumber,
    String? textArabic,
    int? pageNumber,
    int? juzNumber,
    bool? isBookmarked,
  }) {
    return Ayah(
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      textArabic: textArabic ?? this.textArabic,
      pageNumber: pageNumber ?? this.pageNumber,
      juzNumber: juzNumber ?? this.juzNumber,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
