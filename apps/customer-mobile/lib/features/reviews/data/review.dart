/// A single public review of a Hotel (Ratings & Reviews V1, approved
/// business decisions) — never carries any Customer identity, since none
/// is exposed publicly anywhere in this platform.
class Review {
  const Review({
    required this.id,
    required this.rating,
    this.text,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? text;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    rating: json['rating'] as int,
    text: json['text'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
