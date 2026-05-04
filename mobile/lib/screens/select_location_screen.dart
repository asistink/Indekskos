import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SelectLocationScreen extends StatelessWidget {
  final VoidCallback onComplete;
  const SelectLocationScreen({super.key, required this.onComplete});

  Future<void> _setLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_location', location);
    await prefs.setBool('location_set', true);
    onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _setLocation('Yogyakarta, Ind'),
                  child: Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ),
              ),
              const Spacer(flex: 2),

              // Illustration
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circles
                    Positioned(
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha(15),
                        ),
                      ),
                    ),
                    Positioned(
                      child: Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha(25),
                        ),
                      ),
                    ),
                    // Map icon
                    Icon(Icons.map_rounded, size: 60, color: AppColors.primary.withAlpha(80)),
                    // Location pin
                    Positioned(
                      bottom: 50,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 28),
                      ),
                    ),
                    // Search icon
                    Positioned(
                      top: 20, left: 30,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8)]),
                        child: Icon(Icons.search, color: AppColors.primary, size: 20),
                      ),
                    ),
                    // Small decorations
                    Positioned(top: 10, right: 40, child: Icon(Icons.auto_awesome, size: 20, color: AppColors.warning.withAlpha(180))),
                    Positioned(bottom: 20, right: 20, child: Icon(Icons.auto_awesome, size: 16, color: AppColors.primary.withAlpha(100))),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                'Selamat Datang!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilih lokasimu untuk menemukan kos\ndi dekatmu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const Spacer(flex: 3),

              // Gunakan lokasi saat ini
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () => _setLocation('Yogyakarta, Ind'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Gunakan lokasi saat ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 14),

              // Pilih secara manual
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    _showManualLocationPicker(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Pilih secara manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualLocationPicker(BuildContext context) {
    final searchCtrl = TextEditingController();
    final locations = [
      'Yogyakarta, Ind',
      'Sleman, DIY',
      'Bantul, DIY',
      'Pogung, Yogyakarta',
      'Seturan, Yogyakarta',
      'Babarsari, Yogyakarta',
      'Condongcatur, Yogyakarta',
      'Jakal, Yogyakarta',
      'Demangan, Yogyakarta',
      'Gejayan, Yogyakarta',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search Location',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: locations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                  title: Text(locations[i]),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setLocation(locations[i]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
