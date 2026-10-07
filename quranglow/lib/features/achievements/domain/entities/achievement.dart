class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'general',
      isUnlocked: map['isUnlocked'] == true || map['unlockedAt'] != null,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.tryParse(map['unlockedAt'].toString())
          : null,
    );
  }
}
