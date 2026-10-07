class QuranNote {
  final String id;
  final int surahId;
  final int ayahId;
  final int pageNumber;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QuranNote({
    required this.id,
    required this.surahId,
    required this.ayahId,
    required this.pageNumber,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surahId': surahId,
      'ayahId': ayahId,
      'pageNumber': pageNumber,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory QuranNote.fromMap(Map<String, dynamic> map, {String? id}) {
    return QuranNote(
      id: id ?? map['id']?.toString() ?? '',
      surahId: map['surahId'] is int ? map['surahId'] : int.tryParse(map['surahId']?.toString() ?? '1') ?? 1,
      ayahId: map['ayahId'] is int ? map['ayahId'] : int.tryParse(map['ayahId']?.toString() ?? '1') ?? 1,
      pageNumber: map['pageNumber'] is int ? map['pageNumber'] : int.tryParse(map['pageNumber']?.toString() ?? '1') ?? 1,
      content: map['content']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }

  QuranNote copyWith({
    String? id,
    int? surahId,
    int? ayahId,
    int? pageNumber,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuranNote(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      ayahId: ayahId ?? this.ayahId,
      pageNumber: pageNumber ?? this.pageNumber,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
