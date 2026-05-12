/// Core Quran data models for API integration
library;

enum ReciterName {
  misharyrashid('Mishary Rashid Al-Afasy'),
  alhusary('Al-Husary'),
  abdulbasit('Abdul Basit');

  const ReciterName(this.displayName);
  final String displayName;
}

class Surah {
  const Surah({
    required this.id,
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.ayahCount,
    required this.revelationType,
    this.englishName = '',
    this.englishNameTranslation = '',
  });

  final int id;
  final int number;
  final String name;
  final String nameArabic;
  final int ayahCount;
  final String revelationType;
  final String englishName;
  final String englishNameTranslation;

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['number'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nameArabic: json['name'] as String? ?? '',
      ayahCount: json['numberOfAyahs'] as int? ?? 0,
      revelationType: json['revelationType'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      englishNameTranslation: json['englishNameTranslation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'numberOfAyahs': ayahCount,
    'revelationType': revelationType,
    'englishName': englishName,
    'englishNameTranslation': englishNameTranslation,
  };
}

class Ayah {
  const Ayah({
    required this.number,
    required this.text,
    required this.surahNumber,
    required this.ayahNumber,
    this.translation = '',
    this.tafsir = '',
    this.audioUrl = '',
  });

  final int number;
  final String text;
  final int surahNumber;
  final int ayahNumber;
  final String translation;
  final String tafsir;
  final String audioUrl;

  factory Ayah.fromJson(Map<String, dynamic> json) {
    String text = json['text'] as String? ?? '';
    final int surahNum = json['surah']?['number'] as int? ?? 0;
    final int ayahNum = json['numberInSurah'] as int? ?? 0;

    // 🌟 INTELLIGENT BISMILLAH STRIPPER 🌟
    // Only strip if it's the first ayah, NOT in Surah Al-Fatihah (1),
    // and actually contains the prefix.
    if (surahNum > 1 && ayahNum == 1) {
      const String bismillahPrefix = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
      if (text.startsWith(bismillahPrefix)) {
        text = text.replaceFirst(bismillahPrefix, '').trim();
      }
    }

    return Ayah(
      number: json['number'] as int? ?? 0,
      text: text,
      surahNumber: surahNum,
      ayahNumber: ayahNum,
      translation: json['translation']?['text'] as String? ?? '',
      tafsir: json['tafsir']?['text'] as String? ?? '',
      audioUrl: json['audio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'text': text,
    'surah': {'number': surahNumber},
    'numberInSurah': ayahNumber,
    'translation': {'text': translation},
    'tafsir': {'text': tafsir},
    'audio': audioUrl,
  };
}

class Reciter {
  const Reciter({
    required this.name,
    required this.displayName,
    required this.identifier,
  });

  final ReciterName name;
  final String displayName;
  final String identifier;

  static const List<Reciter> defaultReciters = [
    Reciter(
      name: ReciterName.misharyrashid,
      displayName: 'Mishary Rashid Al-Afasy',
      identifier: 'ar.alafasy',
    ),
    Reciter(
      name: ReciterName.alhusary,
      displayName: 'Al-Husary',
      identifier: 'ar.alhusary',
    ),
    Reciter(
      name: ReciterName.abdulbasit,
      displayName: 'Abdul Basit',
      identifier: 'ar.abdulbasit',
    ),
  ];
}

class RecitationAudio {
  const RecitationAudio({
    required this.surahNumber,
    required this.ayahNumber,
    required this.reciter,
    required this.audioUrl,
    required this.duration,
  });

  final int surahNumber;
  final int ayahNumber;
  final Reciter reciter;
  final String audioUrl;
  final Duration duration;

  factory RecitationAudio.fromJson(Map<String, dynamic> json) {
    return RecitationAudio(
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      reciter: Reciter(
        name: ReciterName.misharyrashid,
        displayName: json['reciterName'] as String? ?? '',
        identifier: json['reciterId'] as String? ?? '',
      ),
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: Duration(seconds: json['duration'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'reciterName': reciter.displayName,
    'reciterId': reciter.identifier,
    'audioUrl': audioUrl,
    'duration': duration.inSeconds,
  };
}

class QuranJuz {
  const QuranJuz({
    required this.number,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });

  final int number;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;

  factory QuranJuz.fromJson(Map<String, dynamic> json) {
    return QuranJuz(
      number: json['number'] as int? ?? 0,
      startSurah: json['startSurah'] as int? ?? 0,
      startAyah: json['startAyah'] as int? ?? 0,
      endSurah: json['endSurah'] as int? ?? 0,
      endAyah: json['endAyah'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'startSurah': startSurah,
    'startAyah': startAyah,
    'endSurah': endSurah,
    'endAyah': endAyah,
  };
}
