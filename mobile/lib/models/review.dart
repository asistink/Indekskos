class Review {
  final int id;
  final int listingId;
  final String reviewerName;
  final String? reviewerEmail;
  final int rating;
  final String? comment;
  final bool isApproved;
  final String createdAt;

  Review({
    required this.id,
    required this.listingId,
    required this.reviewerName,
    this.reviewerEmail,
    required this.rating,
    this.comment,
    required this.isApproved,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      listingId: json['listing_id'] ?? 0,
      reviewerName: json['reviewer_name'] ?? '',
      reviewerEmail: json['reviewer_email'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      isApproved: json['is_approved'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
