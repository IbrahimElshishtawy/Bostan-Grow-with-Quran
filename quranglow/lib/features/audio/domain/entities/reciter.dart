class Reciter {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String serverSubfolder;
  final String style; // Murattal / Mujawwad

  const Reciter({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.serverSubfolder,
    this.style = 'مرتل',
  });

  String getAyahAudioUrl(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$serverSubfolder/$s$a.mp3';
  }

  static const List<Reciter> defaultReciters = [
    Reciter(
      id: 'alafasy',
      nameArabic: 'مشاري راشد العفاسي',
      nameEnglish: 'Mishary Rashid Alafasy',
      serverSubfolder: 'Alafasy_128kbps',
    ),
    Reciter(
      id: 'husary',
      nameArabic: 'محمود خليل الحصري',
      nameEnglish: 'Mahmoud Khalil Al-Husary',
      serverSubfolder: 'Husary_128kbps',
    ),
    Reciter(
      id: 'abdulbasit',
      nameArabic: 'عبد الباسط عبد الصمد',
      nameEnglish: 'Abdulbasit Abdussamad',
      serverSubfolder: 'Abdul_Basit_Murattal_192kbps',
    ),
    Reciter(
      id: 'minshawi',
      nameArabic: 'محمد صديق المنشاوي',
      nameEnglish: 'Mohamed Siddiq Al-Minshawi',
      serverSubfolder: 'Minshawy_Murattal_128kbps',
    ),
    Reciter(
      id: 'shatri',
      nameArabic: 'أبو بكر الشاطري',
      nameEnglish: 'Abu Bakr Al-Shatri',
      serverSubfolder: 'Abu_Bakr_Ash-Shaatree_128kbps',
    ),
  ];
}
