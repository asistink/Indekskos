import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/listing.dart';
import '../models/review.dart';
import '../utils/constants.dart';

class ApiService {
  /// Fetch home screen data: featured listings, nearby listings, and areas.
  Future<Map<String, dynamic>> fetchHomeData() async {
    final response = await http.get(Uri.parse(ApiConstants.baseUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final featured = (data['featured'] as List).map((j) => Listing.fromJson(j)).toList();
      final nearby = (data['nearby'] as List).map((j) => Listing.fromJson(j)).toList();
      final areas = List<String>.from(data['areas'] ?? []);
      return {'featured': featured, 'nearby': nearby, 'areas': areas};
    } else {
      throw Exception('Failed to load home data');
    }
  }

  /// Search listings with filters.
  Future<List<Listing>> fetchListings({
    String query = '',
    int minPrice = 0,
    int maxPrice = 0,
    List<String> kosTypes = const [],
    List<String> facilities = const [],
  }) async {
    final params = <String, String>{};
    if (query.isNotEmpty) params['q'] = query;
    if (minPrice > 0) params['min_price'] = minPrice.toString();
    if (maxPrice > 0) params['max_price'] = maxPrice.toString();
    if (kosTypes.isNotEmpty) params['kos_type'] = kosTypes.join(',');
    if (facilities.isNotEmpty) params['facilities'] = facilities.join(',');

    final uri = Uri.parse('${ApiConstants.baseUrl}/search').replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((j) => Listing.fromJson(j)).toList();
    } else {
      throw Exception('Failed to load listings');
    }
  }

  /// Fetch listing detail (includes reviews).
  Future<Map<String, dynamic>> fetchListingDetail(int id) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/kos/$id'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final listing = Listing.fromJson(data['data']);
      final reviews = (data['reviews'] as List).map((j) => Review.fromJson(j)).toList();
      return {'listing': listing, 'reviews': reviews};
    } else {
      throw Exception('Failed to load listing detail');
    }
  }

  /// Submit a new review.
  Future<void> submitReview(int listingId, String name, String? email, int rating, String? comment) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/kos/$listingId/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'reviewer_name': name,
        'reviewer_email': email,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to submit review');
    }
  }
}
