# COVER PAGE
**Judul:** Dokumentasi Perangkat Lunak Indekskos (MVP)
**Versi:** 1.0 Draft Awal
**Tanggal:** 30 April 2026
**Nama Sistem:** Indekskos - Platform Pencarian Kos MVP
**Klien:** Stakeholder Universitas

---

# DAFTAR ISI
1. Bab 1: Project Charter
2. Bab 2: Product Requirements Document (PRD)
3. Bab 3: Software Requirements Specification (SRS)
4. Glosarium
5. Referensi

---

# BAB 1: PROJECT CHARTER

## 1.1 Latar Belakang dan Tujuan
Indekskos adalah platform pencarian kos yang menargetkan mahasiswa di Yogyakarta. Tujuan utama dari MVP ini adalah membuktikan konsep bisnis kepada stakeholder universitas. Fokus utama adalah membangun kepercayaan pengguna melalui ulasan otentik dan memudahkan interaksi langsung dengan pemilik kos melalui WhatsApp. 

## 1.2 Ruang Lingkup (Scope)
**In-Scope:**
- Halaman pencarian dan pencarian kos berdasarkan nama daerah/universitas.
- Halaman detail kos dengan integrasi Google Maps dan tombol WhatsApp langsung.
- Sistem ulasan publik (tanpa login).
- Panel Admin untuk manajemen listing (CRUD) dan persetujuan ulasan.

**Out-of-Scope:**
- Registrasi/Login untuk pencari kos (mahasiswa).
- Portal khusus pemilik kos (Landlord Portal).
- Sistem chat in-app.
- Notifikasi otomatis.

## 1.3 Asumsi dan Kendala
- **Kendala Hosting:** Menggunakan 100% layanan free-tier (Supabase/Neon untuk DB, Render/Koyeb/Fly.io untuk PaaS).
- **Strategi Monetisasi:** Melalui "Featured Listing Fees" dari pemilik kos, bukan komisi transaksi.
- **Tumpukan Teknologi (Tech Stack):** Go (Golang), PostgreSQL, HTMX, Tailwind CSS.

---

# BAB 2: PRODUCT REQUIREMENTS DOCUMENT (PRD)

## 2.1 Visi Produk
Menjadi platform pencarian kos paling transparan dan terpercaya di Yogyakarta dengan pendekatan direct-to-owner tanpa memotong komisi transaksi dari mahasiswa.

## 2.2 Target Pengguna
1. **Pencari Kos (Mahasiswa):** Membutuhkan kos yang sesuai dengan anggaran, lokasi, dan memverifikasi kualitas melalui ulasan.
2. **Admin (Tim Internal):** Mengelola listing properti kos, menetapkan status "Featured", dan memoderasi ulasan.

## 2.3 Fitur Utama (User Stories)
- **Sebagai Mahasiswa**, saya ingin mencari kos berdasarkan nama universitas atau daerah agar bisa menemukan kos terdekat.
- **Sebagai Mahasiswa**, saya ingin memfilter hasil pencarian berdasarkan harga dan fasilitas (AC, WiFi, dll).
- **Sebagai Mahasiswa**, saya ingin bisa langsung menghubungi pemilik kos melalui WhatsApp.
- **Sebagai Mahasiswa**, saya ingin dapat melihat dan memberikan ulasan pada kos.
- **Sebagai Admin**, saya ingin login ke panel admin yang aman.
- **Sebagai Admin**, saya ingin bisa menambah, mengubah, atau menghapus listing kos.
- **Sebagai Admin**, saya ingin menyetujui ulasan pengguna sebelum tampil ke publik.

---

# BAB 3: SOFTWARE REQUIREMENTS SPECIFICATION (SRS)

## 3.1 Kebutuhan Fungsional
1. **Sistem Pencarian dan Filter (Public):**
   - Mendukung pencarian teks pada area dan nama universitas.
   - Filter harga minimum dan maksimum.
   - Filter fasilitas menggunakan checklist (menggunakan HTMX untuk dynamic reload).
2. **Detail Properti:**
   - Menampilkan Thumbnail, Carousel Foto, Harga, Deskripsi, Fasilitas.
   - Mengintegrasikan iframe Google Maps.
   - Menyediakan form ulasan (Nama, Email, Rating 1-5, Komentar) - status *pending* saat disubmit.
   - Tombol "Hubungi Pemilik via WhatsApp" dengan pesan template pre-filled.
3. **Manajemen Admin:**
   - Autentikasi dengan Username dan Password Hash (Bcrypt).
   - Dashboard Statistik (Jumlah Listing, Review Pending).
   - CRUD Form untuk tabel `listings` dan fungsionalitas moderasi untuk tabel `reviews`.

## 3.2 Kebutuhan Non-Fungsional
1. **Keamanan:** Form input akan dilindungi dari SQL Injection (melalui parameterized queries/ORM) dan XSS (melalui html/template escaping bawaan Go). Password Admin di-hash menggunakan algoritma Bcrypt.
2. **Kinerja:** Waktu muat halaman cepat dengan meminimalkan ukuran file dan menggunakan SSR (Server-Side Rendering) digabung dengan HTMX.
3. **Penyebaran (Deployment):** Aplikasi harus 12-Factor App compliant, mendengarkan pada port yang diberikan oleh *environment variable* `PORT` dan database URL melalui `DATABASE_URL`.

## 3.3 Arsitektur Sistem
- **Pola Desain:** Monolith Architecture.
- **Frontend:** Server-Rendered HTML Templates dengan Tailwind CSS untuk styling dan HTMX untuk interaksi SPA-like.
- **Backend:** Go dengan library standar `net/http` atau `go-chi`.
- **Database:** PostgreSQL.

## 3.4 Skema Database
Sesuai rancangan skrip DDL yang diberikan:
- `admins`
- `listings`
- `reviews`

---

# GLOSARIUM
- **MVP:** Minimum Viable Product.
- **HTMX:** Library JavaScript yang memungkinkan akses fungsionalitas AJAX langsung pada HTML.
- **PaaS:** Platform as a Service.
- **CRUD:** Create, Read, Update, Delete.

---

# REFERENSI
- IEEE 830-1998 Standar Rekomendasi Praktik untuk Spesifikasi Kebutuhan Perangkat Lunak.
- Dokumentasi Go: https://go.dev/doc/
- Dokumentasi HTMX: https://htmx.org/docs/
