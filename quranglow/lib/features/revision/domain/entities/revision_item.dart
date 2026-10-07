enum RevisionRating {
  forgotten,
  difficult,
  good,
  easy,
}

class RevisionItem {
  final String id;
  final int surahId;
  final int startAyah;
  final int endAyah;
  final DateTime nextReviewAt;
  final int reviewCount;
  final RevisionRating lastRating;

  const RevisionItem({
    required this.id,
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    required this.nextReviewAt,
    this.reviewCount = 0,
    this.lastRating = RevisionRating.good,
  });

  bool get isDueToday => nextReviewAt.isBefore(DateTime.now().add(const Duration(hours: 1)));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surahId': surahId,
      'startAyah': startAyah,
      'endAyah': endAyah,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'reviewCount': reviewCount,
      'lastRating': lastRating.name,
    };
  }

  factory RevisionItem.fromMap(Map<String, dynamic> map) {
    return RevisionItem(
      id: map['id']?.toString() ?? '',
      surahId: map['surahId'] is int ? map['surahId'] : int.tryParse(map['surahId']?.toString() ?? '1') ?? 1,
      startAyah: map['startAyah'] is int ? map['startAyah'] : 1,
      endAyah: map['endAyah'] is int ? map['endAyah'] : 1,
      nextReviewAt: map['nextReviewAt'] != null
          ? DateTime.tryParse(map['nextReviewAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reviewCount: map['reviewCount'] is int ? map['reviewCount'] : 0,
      lastRating: RevisionRating.values.firstWhere(
        (r) => r.name == map['lastRating'],
        orElse: () => RevisionRating.good,
      ),
    );
  }
}
