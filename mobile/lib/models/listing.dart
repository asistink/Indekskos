class Listing {
  final int id;
  final String name;
  final String area;
  final String address;
  final String? universityNearby;
  final int pricePerMonth;
  final String? description;
  final String? thumbnailUrl;
  final List<String> photoUrls;
  final List<String> facilities;
  final bool isAvailable;
  final String landlordWaNumber;
  final bool isFeatured;
  final double averageRating;
  final String kosType;
  final String? googleMapsIframeUrl;

  Listing({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    this.universityNearby,
    required this.pricePerMonth,
    this.description,
    this.thumbnailUrl,
    required this.photoUrls,
    required this.facilities,
    required this.isAvailable,
    required this.landlordWaNumber,
    required this.isFeatured,
    required this.averageRating,
    required this.kosType,
    this.googleMapsIframeUrl,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      universityNearby: json['university_nearby'],
      pricePerMonth: json['price_per_month'] ?? 0,
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      facilities: List<String>.from(json['facilities'] ?? []),
      isAvailable: json['is_available'] ?? false,
      landlordWaNumber: json['landlord_wa_number'] ?? '',
      isFeatured: json['is_featured'] ?? false,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      kosType: json['kos_type'] ?? 'campur',
      googleMapsIframeUrl: json['google_maps_iframe_url'],
    );
  }
}
