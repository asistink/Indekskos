import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  List<Listing> _featured = [];
  List<Listing> _nearby = [];
  List<String> _areas = [];
  bool _isLoading = true;

  // Filter state
  List<String> _filterKosTypes = [];
  double _filterMinPrice = 300000;
  double _filterMaxPrice = 5000000;
  List<String> _filterFacilities = [];
  String? _filterTargetCampus;
  double? _filterMotorDistance;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.fetchHomeData();
      setState(() {
        _featured = data['featured'];
        _nearby = data['nearby'];
        _areas = data['areas'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        selectedKosTypes: _filterKosTypes,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
        selectedFacilities: _filterFacilities,
        targetCampus: _filterTargetCampus,
        motorDistanceMinutes: _filterMotorDistance,
        onApply: (kosTypes, minPrice, maxPrice, facilities, targetCampus, motorDistanceMinutes) {
          setState(() {
            _filterKosTypes = kosTypes;
            _filterMinPrice = minPrice;
            _filterMaxPrice = maxPrice;
            _filterFacilities = facilities;
            _filterTargetCampus = targetCampus;
            _filterMotorDistance = motorDistanceMinutes;
          });
          _doSearch();
        },
      ),
    );
  }

  Future<void> _doSearch() async {
    setState(() => _isLoading = true);
    try {
      final results = await _api.fetchListings(
        query: _searchCtrl.text,
        minPrice: _filterMinPrice.toInt(),
        maxPrice: _filterMaxPrice.toInt(),
        kosTypes: _filterKosTypes,
        facilities: _filterFacilities,
        targetCampus: _filterTargetCampus,
        motorDistanceMinutes: _filterMotorDistance,
      );
      setState(() {
        _nearby = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(onRefresh: _loadHome, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildAreaPopuler(),
          _buildRekomendasi(),
          _buildNearby(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // === HEADER ===
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lokasi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  const Text('Yogyakarta, Ind', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _headerIcon(Icons.notifications_none, () {}),
              const SizedBox(width: 8),
              _headerIcon(Icons.chat_bubble_outline, () {}),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/admin/login'),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  // === SEARCH BAR ===
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _doSearch(),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _openFilter,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.tune, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // === AREA POPULER (Horizontal chips) ===
  Widget _buildAreaPopuler() {
    if (_areas.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _sectionHeader('Area Populer', 'See all', () {}),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _areas.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () {
                  _searchCtrl.text = _areas[i];
                  _doSearch();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == 1 ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: i == 1 ? AppColors.primary : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: i == 1 ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
                        child: Icon(Icons.location_city, size: 14, color: i == 1 ? Colors.white : AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(_areas[i], style: TextStyle(color: i == 1 ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // === REKOMENDASI (Horizontal cards) ===
  Widget _buildRekomendasi() {
    if (_featured.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _sectionHeader('Rekomendasi', 'Lihat Semua', () {}),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featured.length,
            itemBuilder: (context, i) => _buildFeaturedCard(_featured[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Listing l) {
    return GestureDetector(
      onTap: () => context.push('/detail/${l.id}'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white),
        child: Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(l.thumbnailUrl ?? '', height: 220, width: 200, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 220, width: 200, color: Colors.grey[300], child: const Icon(Icons.image, size: 40))),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
                ),
              ),
            ),
            // Favorite icon
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border, size: 18, color: AppColors.primary),
              ),
            ),
            // Bottom info
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                        child: Text('Kos ${l.kosType[0].toUpperCase()}${l.kosType.substring(1)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text(formatCurrency.format(l.pricePerMonth), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      const Text('/bulan', style: TextStyle(color: Colors.white70, fontSize: 9)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(l.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.white70),
                      const SizedBox(width: 2),
                      Expanded(child: Text(l.address, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === NEARBY (Vertical list) ===
  Widget _buildNearby() {
    return Column(
      children: [
        _sectionHeader('Di sekitar lokasimu', 'Lihat Semua', () {}),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _nearby.length,
          itemBuilder: (context, i) => _buildNearbyCard(_nearby[i]),
        ),
      ],
    );
  }

  Widget _buildNearbyCard(Listing l) {
    return GestureDetector(
      onTap: () => context.push('/detail/${l.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(l.thumbnailUrl ?? '', width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.image))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(child: Text(l.address, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${formatCurrency.format(l.pricePerMonth)}/bln', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.star, size: 14, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(l.averageRating > 0 ? l.averageRating.toStringAsFixed(1) : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === SECTION HEADER ===
  Widget _sectionHeader(String title, String actionText, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: onAction,
            child: Text(actionText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
