class Bookmark {
  const Bookmark({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.createdAt,
    this.note = '',
    this.tags = const [],
    this.isFavorite = false,
    this.color = '',
  });

  final String id;
  final int surahNumber;
  final int ayahNumber;
  final DateTime createdAt;
  final String note;
  final List<String> tags;
  final bool isFavorite;
  final String color;

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String? ?? '',
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: json['note'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
      color: json['color'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
    'tags': tags,
    'isFavorite': isFavorite,
    'color': color,
  };

  Bookmark copyWith({
    String? id,
    int? surahNumber,
    int? ayahNumber,
    DateTime? createdAt,
    String? note,
    List<String>? tags,
    bool? isFavorite,
    String? color,
  }) {
    return Bookmark(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      color: color ?? this.color,
    );
  }
}

class BookmarkFolder {
  const BookmarkFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description = '',
    this.bookmarks = const [],
    this.color = '',
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String description;
  final List<Bookmark> bookmarks;
  final String color;

  int get bookmarkCount => bookmarks.length;

  factory BookmarkFolder.fromJson(Map<String, dynamic> json) {
    return BookmarkFolder(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String? ?? '',
      bookmarks:
          (json['bookmarks'] as List<dynamic>?)
              ?.map((b) => Bookmark.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      color: json['color'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'description': description,
    'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    'color': color,
  };

  BookmarkFolder copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? description,
    List<Bookmark>? bookmarks,
    String? color,
  }) {
    return BookmarkFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      bookmarks: bookmarks ?? this.bookmarks,
      color: color ?? this.color,
    );
  }

  BookmarkFolder addBookmark(Bookmark bookmark) {
    return copyWith(bookmarks: [...bookmarks, bookmark]);
  }

  BookmarkFolder removeBookmark(String bookmarkId) {
    return copyWith(
      bookmarks: bookmarks.where((b) => b.id != bookmarkId).toList(),
    );
  }
}

class BookmarkStats {
  const BookmarkStats({
    required this.totalBookmarks,
    required this.totalFolders,
    required this.favoriteCount,
    required this.tagCount,
  });

  final int totalBookmarks;
  final int totalFolders;
  final int favoriteCount;
  final int tagCount;
}
