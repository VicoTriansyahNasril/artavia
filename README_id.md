# Artavia - Pencatat Keuangan 💸

*Baca ini dalam bahasa lain: [English](README.md) | [Bahasa Indonesia](README_id.md)*

> **🚧 Status Pengembangan: Aktif Dikembangkan**  
> *Proyek ini saat ini masih dalam tahap pengembangan aktif. Fitur, antarmuka (UI), dan struktur database dapat berubah sewaktu-waktu. Segala bentuk masukan (feedback) sangat diharapkan!*

Artavia adalah aplikasi mobile manajemen keuangan dan pengeluaran yang mengutamakan privasi (*local-first*), dibangun dengan menggunakan Flutter. Didesain dengan estetika premium dan animasi mikro (*micro-animations*) yang halus, aplikasi ini membantu Anda mengelola keuangan harian, melacak berbagai rekening, dan menganalisis kebiasaan pengeluaran Anda—semuanya dilakukan sepenuhnya secara *offline*.

## ✨ Fitur Utama
- **Privasi (Lokal)**: Semua data tersimpan di HP (SQLite). Cadangan Google Drive opsional ke folder khusus Artavia dan bisa dikunci kata sandi (AES-256-GCM).
- **Catat cepat**: Satu layar papan angka untuk pengeluaran, pemasukan, dan transfer, dengan + − × ÷. Semua kategori tampil sesuai urutanmu; papan angka muncul setelah kategori dipilih, dan nominal tetap terlihat walau di-scroll. Tanggal ada di dekat nominal, catatan diketik langsung di samping rekening, dan rekening terakhir dipilih otomatis.
- **Nominal mudah dibaca**: Isian Rupiah otomatis memakai pemisah ribuan saat diketik, mengikuti pengaturan 1.000 / 1,000.
- **Transfer yang ingat biaya admin**: Biaya per pasangan rekening dipilih otomatis, bisa dipotong dari saldo asal atau dari uang diterima, dan dicatat sebagai pengeluaran "Biaya admin".
- **Transaksi, Laporan, Rekening, Pengaturan**: Ringkasan periode dengan insight mingguan, kartu anggaran, dan daftar per hari; laporan minggu/bulan/tahun dengan grafik tren dan donat kategori; rekening per kelompok dengan kekayaan bersih dan arsip.
- **Anggaran, Cari, Kalender**: "Perlu perhatian" dan "Aman" dengan batas aman harian, saran ejaan saat mencari, dan kalender bertitik pemasukan/pengeluaran.
- **107 ikon, 12 warna**: Kategori memakai ikon Lucide dalam 13 kelompok, bisa diarsipkan dan diurutkan dengan digeser (urutan yang tampil di Catat, atau sekali ketuk urut menurut pemakaian). Rekening memakai pilihan ikon khusus uang dan tabungan.
- **Urungkan & privasi**: Hapus bisa diurungkan 5 detik; satu ketukan menyembunyikan semua nominal.
- **Excel & CSV**: Ekspor per lembar, impor 3 langkah dengan deteksi duplikat dan pembatalan 7 hari.
- **Desain "Kobalt"**: Tema gelap, terang, atau ikuti sistem, permukaan kaca, ukuran teks hingga 150 %, PIN dengan sidik jari.

## 🛠️ Teknologi yang Digunakan
- **Framework**: [Flutter](https://flutter.dev/)
- **Manajemen State & Routing**: [GetX](https://pub.dev/packages/get)
- **Database Lokal**: [sqflite](https://pub.dev/packages/sqflite)
- **Cadangan**: [google_sign_in](https://pub.dev/packages/google_sign_in) + [Google Drive API](https://pub.dev/packages/googleapis) (`drive.appdata`, `drive.file`)
- **UI**: [Ikon Lucide](https://pub.dev/packages/lucide_icons_flutter), [fl_chart](https://pub.dev/packages/fl_chart), Plus Jakarta Sans
- **Arsitektur**: Feature-Based Architecture

## 📱 Platform
Android (`id.artavia.app`, minSdk 24), dibagikan sebagai APK. Proyek iOS tetap bisa di-build, tetapi cadangan Google Drive baru dikonfigurasi untuk Android.

## 🚀 Cara Menjalankan

Karena ini adalah proyek Flutter, pastikan Anda telah menginstal Flutter SDK di komputer Anda.

1. **Clone repository ini**
   ```bash
   git clone https://github.com/VicoTriansyahNasril/artavia.git
   cd artavia
   ```
2. **Install dependensi**
   ```bash
   flutter pub get
   ```
3. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

### APK rilis
```bash
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```
Build rilis ditandatangani `android/upload-keystore.jks` lewat `android/key.properties`. Keduanya diabaikan git, jadi simpan cadangannya: update aplikasi wajib ditandatangani kunci yang sama. Tanpa kedua file itu, build memakai kunci debug.

### Cadangan Google Drive
Login hanya berfungsi untuk aplikasi yang terdaftar di Google Cloud dengan nama paket dan SHA-1 penanda tangannya. Pada *fork*, buat OAuth client sendiri lalu isi Web client ID-nya di `GoogleDriveService.webClientId` ([lib/core/services/google_drive_service.dart](lib/core/services/google_drive_service.dart)). Panduan langkah demi langkah: [docs/google-drive-android.md](docs/google-drive-android.md). Kebijakan privasi: [vicotriansyahnasril.github.io/artavia/privacy.html](https://vicotriansyahnasril.github.io/artavia/privacy.html).

### Ikon aplikasi & splash
Ikon launcher di `android/.../res/mipmap-*` dan `ios/.../AppIcon.appiconset` berasal dari paket desain Artavia. Splash mengikuti tema terang/gelap sistem; setelah mengganti `assets/brand/splash-icon.png`, jalankan:
```bash
dart run flutter_native_splash:create
```

## 📝 Lisensi
Proyek ini bersifat *open-source*. Silakan di-*fork* dan dimodifikasi sesuai kebutuhan!
