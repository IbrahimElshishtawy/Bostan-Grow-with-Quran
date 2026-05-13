/// Tafsir models for Quranic interpretation
enum TafsirSource {
  ibnKathir('Ibn Kathir', 'ar.ibnkathir'),
  alSaadi('Al-Saadi', 'ar.alsaadi'),
  muyassar('Al-Muyassar', 'ar.muyassar'),
  english('English', 'en.tafsir_english');

  const TafsirSource(this.displayName, this.identifier);
  final String displayName;
  final String identifier;
}

class TafsirText {
  const TafsirText({
    required this.surahNumber,
    required this.ayahNumber,
    required this.source,
    required this.text,
    this.author = '',
    this.language = 'ar',
  });

  final int surahNumber;
  final int ayahNumber;
  final TafsirSource source;
  final String text;
  final String author;
  final String language;

  factory TafsirText.fromJson(Map<String, dynamic> json) {
    return TafsirText(
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      source: TafsirSource.values.firstWhere(
        (s) => s.identifier == json['source'],
        orElse: () => TafsirSource.muyassar,
      ),
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? '',
      language: json['language'] as String? ?? 'ar',
    );
  }

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'source': source.identifier,
    'text': text,
    'author': author,
    'language': language,
  };
}

class TafsirCollection {
  const TafsirCollection({
    required this.surahNumber,
    required this.ayahNumber,
    required this.tafsirs,
  });

  final int surahNumber;
  final int ayahNumber;
  final List<TafsirText> tafsirs;

  TafsirText? getTafsir(TafsirSource source) {
    try {
      return tafsirs.firstWhere((t) => t.source == source);
    } catch (e) {
      return null;
    }
  }

  factory TafsirCollection.fromJson(Map<String, dynamic> json) {
    return TafsirCollection(
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      tafsirs: (json['tafsirs'] as List<dynamic>?)
              ?.map((t) => TafsirText.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'tafsirs': tafsirs.map((t) => t.toJson()).toList(),
  };
}
