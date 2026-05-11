import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> selectedKosTypes;
  final double minPrice;
  final double maxPrice;
  final List<String> selectedFacilities;
  final Function(List<String> kosTypes, double minPrice, double maxPrice, List<String> facilities) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedKosTypes,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedFacilities,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> _kosTypes;
  late RangeValues _priceRange;
  late List<String> _facilities;

  /// Format angka ke format mata uang Indonesia (Rp300.000)
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  final List<String> _allKosTypes = ['putra', 'putri', 'campur'];
  final List<Map<String, dynamic>> _allFacilities = [
    {'name': 'Listrik', 'icon': Icons.bolt},
    {'name': 'KM Dalam', 'icon': Icons.bathtub_outlined},
    {'name': 'AC', 'icon': Icons.ac_unit},
    {'name': 'WiFi', 'icon': Icons.wifi},
    {'name': 'Parkir Motor', 'icon': Icons.two_wheeler},
    {'name': 'Laundry', 'icon': Icons.local_laundry_service},
    {'name': 'Dapur Bersama', 'icon': Icons.kitchen},
    {'name': 'CCTV', 'icon': Icons.videocam},
  ];

  @override
  void initState() {
    super.initState();
    _kosTypes = List.from(widget.selectedKosTypes);
    _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
    _facilities = List.from(widget.selectedFacilities);
  }

  void _reset() {
    setState(() {
      _kosTypes = [];
      _priceRange = const RangeValues(300000, 5000000);
      _facilities = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Tipe Kos
            const Text('Tipe Kos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._allKosTypes.map((type) => CheckboxListTile(
              title: Text(type[0].toUpperCase() + type.substring(1)),
              value: _kosTypes.contains(type),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.trailing,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _kosTypes.add(type);
                  } else {
                    _kosTypes.remove(type);
                  }
                });
              },
            )),
            const SizedBox(height: 16),

            // Rentang Harga
            const Text('Rentang Harga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RangeSlider(
              values: _priceRange,
              min: 300000,
              max: 5000000,
              divisions: 47,
              activeColor: AppColors.primary,
              labels: RangeLabels(
                _currencyFormat.format(_priceRange.start.toInt()),
                _currencyFormat.format(_priceRange.end.toInt()),
              ),
              onChanged: (values) => setState(() => _priceRange = values),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_currencyFormat.format(_priceRange.start.toInt()), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(_currencyFormat.format(_priceRange.end.toInt()), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),

            // Fasilitas
            const Text('Fasilitas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _allFacilities.map((fac) {
                final isSelected = _facilities.contains(fac['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _facilities.remove(fac['name']);
                      } else {
                        _facilities.add(fac['name']);
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        child: Icon(fac['icon'], color: isSelected ? AppColors.primary : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(fac['name'], style: TextStyle(fontSize: 11, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_kosTypes, _priceRange.start, _priceRange.end, _facilities);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
