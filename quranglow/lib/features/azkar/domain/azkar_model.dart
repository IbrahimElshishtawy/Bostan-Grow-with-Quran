class Zikr {
  final String category;
  final String text;
  final String? count;
  final String? description;
  final String? reference;

  Zikr({
    required this.category,
    required this.text,
    this.count,
    this.description,
    this.reference,
  });
}

class AzkarData {
  static List<Zikr> getByCategory(String category) {
    switch (category) {
      case 'أذكار الصباح': return sabahAzkar;
      case 'أذكار المساء': return masaaAzkar;
      case 'أذكار النوم': return sleepAzkar;
      case 'أذكار الاستيقاظ': return wakeUpAzkar;
      case 'أذكار بعد الصلاة': return postPrayerAzkar;
      default: return [];
    }
  }

  static final List<Zikr> sabahAzkar = [
    Zikr(
      category: 'أذكار الصباح',
      text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      count: '1',
      reference: 'مسلم',
    ),
    Zikr(
      category: 'أذكار الصباح',
      text: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      count: '3',
      reference: 'أبو داود والترمذي',
    ),
    Zikr(
      category: 'أذكار الصباح',
      text: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صلى الله عليه وسلم نَبِيًّا',
      count: '3',
      reference: 'أبو داود والترمذي',
    ),
    Zikr(
      category: 'أذكار الصباح',
      text: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      count: '1',
      reference: 'الحاكم',
    ),
  ];

  static final List<Zikr> masaaAzkar = [
    Zikr(
      category: 'أذكار المساء',
      text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      count: '1',
      reference: 'مسلم',
    ),
    Zikr(
      category: 'أذكار المساء',
      text: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      count: '3',
      reference: 'مسلم',
    ),
  ];

  static final List<Zikr> sleepAzkar = [
    Zikr(
      category: 'أذكار النوم',
      text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا، بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
      count: '1',
      reference: 'البخاري ومسلم',
    ),
    Zikr(
      category: 'أذكار النوم',
      text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
      count: '3',
      reference: 'أبو داود والترمذي',
    ),
  ];

  static final List<Zikr> wakeUpAzkar = [
    Zikr(
      category: 'أذكار الاستيقاظ',
      text: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      count: '1',
      reference: 'البخاري',
    ),
  ];

  static final List<Zikr> postPrayerAzkar = [
    Zikr(
      category: 'أذكار بعد الصلاة',
      text: 'أَسْتَغْفِرُ اللَّهَ (ثلاثاً)، اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      count: '1',
      reference: 'مسلم',
    ),
  ];
}
