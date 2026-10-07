import 'ayah.dart';

class QuranPage {
  final int pageNumber;
  final int juzNumber;
  final String primarySurahName;
  final List<Ayah> ayahs;

  const QuranPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.primarySurahName,
    required this.ayahs,
  });
}
