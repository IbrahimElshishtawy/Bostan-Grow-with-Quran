class FavoriteAudio {
  final String id; // editionId_chapter
  final String editionId;
  final int chapter;
  final String surahName;
  final String reciterName;
  final DateTime addedAt;

  FavoriteAudio({
    required this.id,
    required this.editionId,
    required this.chapter,
    required this.surahName,
    required this.reciterName,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'editionId': editionId,
      'chapter': chapter,
      'surahName': surahName,
      'reciterName': reciterName,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory FavoriteAudio.fromMap(Map<dynamic, dynamic> map) {
    return FavoriteAudio(
      id: map['id'] as String,
      editionId: map['editionId'] as String,
      chapter: map['chapter'] as int,
      surahName: map['surahName'] as String,
      reciterName: map['reciterName'] as String,
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }
}
