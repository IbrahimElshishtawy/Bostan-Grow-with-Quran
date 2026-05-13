// ignore_for_file: unnecessary_null_in_if_null_operators

class Aya {
  final int globalId; // مُعرّف عالمي إن وُجد
  final int surah; // رقم السورة
  final int number; // رقم عالمي/متسلسل حسب المصدر
  final int numberInSurah; // رقم الآية داخل السورة
  final String text;
  final String? translation;
  final String? audioUrl;

  const Aya({
    required this.globalId,
    required this.surah,
    required this.number,
    required this.numberInSurah,
    required this.text,
    this.translation,
    this.audioUrl,
  });

  factory Aya.fromMap(Map<String, dynamic> m) {
    final int globalId = (m['global'] ?? m['globalId'] ?? 0) as int;
    final int surah = (m['surah'] ?? m['chapter'] ?? 0) as int;

    // مصادر محتملة لرقم الآية داخل السورة
    final int numberInSurah =
        (m['numberInSurah'] ??
                m['number_in_surah'] ??
                m['ayah'] ??
                m['aya'] ??
                m['verse_in_surah'] ??
                m['verseNumber'] ??
                m['verse_number'] ??
                m['number'] ?? // fallback
                0)
            as int;

    // بعض الـ APIs تستخدم "number" كرقم عالمي، خليه منفصل
    final int number =
        (m['globalNumber'] ??
                m['global_number'] ??
                m['number_global'] ??
                m['number'] ?? // fallback لو نفس الحقل
                numberInSurah)
            as int;

    String text = (m['text'] ?? m['arabic'] ?? '') as String;
    
    // 🌟 INTELLIGENT BISMILLAH STRIPPER 🌟
    if (surah > 1 && numberInSurah == 1) {
      const String bismillahPrefix = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
      if (text.startsWith(bismillahPrefix)) {
        text = text.replaceFirst(bismillahPrefix, '').trim();
      }
    }

    final String? translation =
        (m['translation'] ?? m['translation_text'] ?? null) as String?;
    final String? audioUrl = (m['audio'] ?? m['audioUrl'] ?? null) as String?;

    return Aya(
      globalId: globalId,
      surah: surah,
      number: number,
      numberInSurah: numberInSurah,
      text: text,
      translation: translation,
      audioUrl: audioUrl,
    );
  }

  Aya copyWith({
    int? globalId,
    int? surah,
    int? number,
    int? numberInSurah,
    String? text,
    String? translation,
    String? audioUrl,
  }) {
    return Aya(
      globalId: globalId ?? this.globalId,
      surah: surah ?? this.surah,
      number: number ?? this.number,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      audioUrl: audioUrl ?? this.audioUrl,
    );
  }
}
