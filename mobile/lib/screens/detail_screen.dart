import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/listing.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class DetailScreen extends StatefulWidget {
  final int listingId;
  const DetailScreen({super.key, required this.listingId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _api = ApiService();
  Listing? _listing;
  List<Review> _reviews = [];
  bool _isLoading = true;
  int _selectedPhotoIndex = 0;
  bool _descExpanded = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _api.fetchListingDetail(widget.listingId);
      setState(() {
        _listing = data['listing'];
        _reviews = data['reviews'];
        _isLoading = false;
        
        if (_listing?.videoUrl != null && _listing!.videoUrl!.isNotEmpty) {
          final url = '${ApiConstants.baseUrl}${_listing!.videoUrl}';
          _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _launchWa(String number) async {
    final url = Uri.parse('https://wa.me/$number?text=Halo,%20saya%20tertarik%20dengan%20kos%20Anda');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showReviewDialog() {
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tulis Ulasan'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nama Anda', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
                onTap: () => ss(() => rating = i + 1),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.warning, size: 36)),
              ))),
              const SizedBox(height: 14),
              TextField(controller: commentCtrl, maxLines: 3, decoration: InputDecoration(labelText: 'Komentar', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  await _api.submitReview(widget.listingId, nameCtrl.text, null, rating, commentCtrl.text.isNotEmpty ? commentCtrl.text : null);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ulasan terkirim! Menunggu persetujuan.')));
                    _fetchDetail();
                  }
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Kirim', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    if (_listing == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Kos tidak ditemukan')));
    final l = _listing!;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Build photo list: thumbnail first, then photo_urls
    final photos = <String>[];
    if (l.thumbnailUrl != null && l.thumbnailUrl!.isNotEmpty) photos.add(l.thumbnailUrl!);
    photos.addAll(l.photoUrls.where((p) => !photos.contains(p)));
    if (photos.isEmpty) photos.add('');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // === APP BAR + PHOTO ===
                Stack(
                  children: [
                    // Main photo
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Image.network(photos[_selectedPhotoIndex], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)))),
                    ),
                    // Top bar
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
                              const Expanded(child: Center(child: Text('Detail Kos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                              _circleBtn(Icons.share, () {}),
                              const SizedBox(width: 8),
                              _circleBtn(Icons.favorite_border, () {}),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // === Photo thumbnails ===
                if (photos.length > 1)
                  Container(
                    height: 64, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, itemCount: photos.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() => _selectedPhotoIndex = i),
                        child: Container(
                          width: 64, margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: i == _selectedPhotoIndex ? AppColors.primary : Colors.transparent, width: 2),
                          ),
                          child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(photos[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]))),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // === KOS TYPE + RATING ===
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                        child: Text('Kos ${l.kosType[0].toUpperCase()}${l.kosType.substring(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(l.averageRating > 0 ? l.averageRating.toStringAsFixed(1) : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(' (${_reviews.length} ulasan)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                    
                    if (l.isVideoVerified) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.verified, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text('Real-View Verified', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    ],
                    const SizedBox(height: 12),

                    // === NAME ===
                    Text(l.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),

                    // === ADDRESS + PRICE ===
                    Row(children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(l.address, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                      Text(fmt.format(l.pricePerMonth), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('/bln', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                    
                    if (l.targetCampus != null && l.motorDistanceMinutes != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.two_wheeler, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('${l.motorDistanceMinutes} menit ke ${l.targetCampus}', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],

                    if (l.lastConfirmedAt == null || DateTime.now().difference(l.lastConfirmedAt!).inDays > 3) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.warning.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning.withAlpha(100))),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Status ketersediaan kos ini belum dikonfirmasi oleh pemilik baru-baru ini.', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      )
                    ],

                    const SizedBox(height: 20),

                    // === VIDEO WALKTHROUGH ===
                    if (_videoController != null && _videoController!.value.isInitialized) ...[
                      const Text('Unfiltered 30s Walkthrough', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.black.withAlpha(100), shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // === TENTANG KOS INI ===
                    const Text('Tentang Kos Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      l.description ?? 'Tidak ada deskripsi.',
                      maxLines: _descExpanded ? null : 3, overflow: _descExpanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                    ),
                    if ((l.description ?? '').length > 100)
                      GestureDetector(
                        onTap: () => setState(() => _descExpanded = !_descExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_descExpanded ? 'Lebih sedikit' : 'Read more', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // === SPESIFIKASI ===
                    const Text('Spesifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSpecGrid(l),
                    const SizedBox(height: 20),

                    // === FASILITAS KAMAR ===
                    const Text('Fasilitas Kamar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildFacilityChips(l.facilities.where((f) => ['Kasur', 'AC', 'Lemari', 'Meja', 'Kursi', 'Bantal', 'Guling', 'TV', 'Kulkas'].contains(f)).toList()),

                    // === FASILITAS KAMAR MANDI ===
                    const SizedBox(height: 16),
                    const Text('Fasilitas Kamar Mandi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildFacilityChips(l.facilities.where((f) => ['KM Dalam', 'Shower', 'Kloset Duduk', 'Ember'].contains(f)).toList()),

                    // === FASILITAS UMUM ===
                    const SizedBox(height: 16),
                    const Text('Fasilitas Umum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildFacilityChips(l.facilities.where((f) => ['Dapur Bersama', 'Ruang Cuci', 'Ruang Tamu', 'Parkir Motor', 'WiFi', 'Listrik', 'Laundry', 'CCTV', 'Taman'].contains(f)).toList()),
                    const SizedBox(height: 20),

                    // === KONTAK ===
                    const Text('Kontak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      CircleAvatar(radius: 22, backgroundColor: AppColors.primary.withAlpha(30), child: const Icon(Icons.person, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Pemilik Kos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(l.landlordWaNumber, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ])),
                      _contactIcon(Icons.phone, () {}),
                      const SizedBox(width: 8),
                      _contactIcon(Icons.chat_bubble_outline, () => _launchWa(l.landlordWaNumber)),
                      const SizedBox(width: 8),
                      _contactIcon(Icons.video_call, () {}),
                    ]),
                    const SizedBox(height: 24),

                    // === LOKASI & FASILITAS PUBLIK ===
                    const Text('Lokasi & Fasilitas Publik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _publicFacChip(Icons.store, 'Warindo'),
                        _publicFacChip(Icons.local_gas_station, 'Pom Bensin'),
                        _publicFacChip(Icons.mosque, 'Masjid'),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    // Map placeholder
                    Container(
                      height: 140, width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent(l.address)},Yogyakarta&zoom=15&size=600x200&maptype=roadmap&key=DEMO',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map, size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 4),
                              Text('Peta Lokasi', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // === ULASAN ===
                    Row(children: [
                      Text('Ulasan (${_reviews.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(onTap: _showReviewDialog, child: const Text('Tulis Ulasan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))),
                    ]),
                    const SizedBox(height: 12),
                    if (_reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Belum ada ulasan', style: TextStyle(color: AppColors.textSecondary))),
                      )
                    else
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _reviews.length,
                          itemBuilder: (_, i) => _buildReviewCard(_reviews[i]),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ]),
            ),
          ),

          // === BOTTOM BUTTON ===
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, -2))]),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => _launchWa(l.landlordWaNumber),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Sewa Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withAlpha(200), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4)]),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _contactIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _publicFacChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildSpecGrid(Listing l) {
    final specs = [
      {'icon': Icons.person, 'label': 'Kapasitas', 'value': '1 orang'},
      {'icon': Icons.home, 'label': 'Tipe', 'value': l.kosType[0].toUpperCase() + l.kosType.substring(1)},
      {'icon': Icons.straighten, 'label': 'Ukuran', 'value': '3x4 m'},
      {'icon': Icons.local_parking, 'label': 'Parkir', 'value': l.facilities.contains('Parkir Motor') ? 'Ada' : 'Tidak'},
      {'icon': Icons.bathtub_outlined, 'label': 'Kamar Mandi', 'value': l.facilities.contains('KM Dalam') ? 'Dalam' : 'Luar'},
      {'icon': Icons.wifi, 'label': 'WiFi', 'value': l.facilities.contains('WiFi') ? 'Tersedia' : 'Tidak'},
    ];
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8,
      children: specs.map((s) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [Icon(s['icon'] as IconData, size: 14, color: AppColors.textSecondary), const SizedBox(width: 4), Text(s['label'] as String, style: TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
          const SizedBox(height: 2),
          Text(s['value'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      )).toList(),
    );
  }

  Widget _buildFacilityChips(List<String> items) {
    if (items.isEmpty) return Text('Tidak tersedia', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
    final iconMap = <String, IconData>{
      'Kasur': Icons.bed, 'AC': Icons.ac_unit, 'Lemari': Icons.door_sliding, 'Meja': Icons.desk, 'Kursi': Icons.chair,
      'Bantal': Icons.rectangle, 'Guling': Icons.rectangle_outlined, 'TV': Icons.tv, 'Kulkas': Icons.kitchen,
      'KM Dalam': Icons.bathtub, 'Shower': Icons.shower, 'Kloset Duduk': Icons.wc, 'Ember': Icons.water_drop,
      'Dapur Bersama': Icons.soup_kitchen, 'Ruang Cuci': Icons.local_laundry_service, 'Ruang Tamu': Icons.weekend,
      'Parkir Motor': Icons.two_wheeler, 'WiFi': Icons.wifi, 'Listrik': Icons.bolt, 'Laundry': Icons.local_laundry_service,
      'CCTV': Icons.videocam, 'Taman': Icons.park,
    };
    return Wrap(spacing: 12, runSpacing: 10, children: items.map((f) => Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(iconMap[f] ?? Icons.check_circle_outline, size: 18, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(f, style: const TextStyle(fontSize: 13)),
    ])).toList());
  }

  Widget _buildReviewCard(Review r) {
    return Container(
      width: 220, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withAlpha(40), child: Text(r.reviewerName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14))),
          const SizedBox(width: 10),
          Expanded(child: Text(r.reviewerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 12, color: AppColors.warning))),
        ]),
        if (r.comment != null) ...[
          const SizedBox(height: 8),
          Text(r.comment!, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}
