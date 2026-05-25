import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/listing.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../widgets/filter_bottom_sheet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  List<Listing> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  List<String> _filterKosTypes = [];
  double _filterMinPrice = 300000;
  double _filterMaxPrice = 5000000;
  List<String> _filterFacilities = [];
  String? _filterTargetCampus;
  double? _filterMotorDistance;

  Future<void> _doSearch() async {
    setState(() { _isLoading = true; _hasSearched = true; });
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
      setState(() { _results = results; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore Kos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _doSearch(),
                    decoration: InputDecoration(
                      hintText: 'Cari kos, area, universitas...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _openFilter,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Active filters
          if (_filterKosTypes.isNotEmpty || _filterFacilities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._filterKosTypes.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(label: Text(t, style: const TextStyle(fontSize: 11)), backgroundColor: AppColors.primary.withOpacity(0.1), side: BorderSide.none, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                    )),
                    ..._filterFacilities.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(label: Text(f, style: const TextStyle(fontSize: 11)), backgroundColor: AppColors.primary.withOpacity(0.1), side: BorderSide.none, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                    )),
                  ],
                ),
              ),
            ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : !_hasSearched
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search, size: 60, color: Colors.grey[300]), const SizedBox(height: 12), Text('Cari kos impianmu', style: TextStyle(color: AppColors.textSecondary))]))
                    : _results.isEmpty
                        ? Center(child: Text('Tidak ditemukan', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) {
                              final l = _results[i];
                              return GestureDetector(
                                onTap: () => context.push('/detail/${l.id}'),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                                  child: Row(
                                    children: [
                                      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(l.thumbnailUrl ?? '', width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: Colors.grey[300], child: const Icon(Icons.image)))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(l.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Row(children: [const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary), const SizedBox(width: 2), Expanded(child: Text(l.address, style: TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                                          const SizedBox(height: 6),
                                          Row(children: [
                                            Text('${fmt.format(l.pricePerMonth)}/bln', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                            const Spacer(),
                                            const Icon(Icons.star, size: 14, color: AppColors.warning),
                                            const SizedBox(width: 2),
                                            Text(l.averageRating > 0 ? l.averageRating.toStringAsFixed(1) : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ]),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
