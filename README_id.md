# Artavia - Pencatat Keuangan 💸

*Baca ini dalam bahasa lain: [English](README.md) | [Bahasa Indonesia](README_id.md)*

> **🚧 Status Pengembangan: Aktif Dikembangkan**  
> *Proyek ini saat ini masih dalam tahap pengembangan aktif. Fitur, antarmuka (UI), dan struktur database dapat berubah sewaktu-waktu. Segala bentuk masukan (feedback) sangat diharapkan!*

Artavia adalah aplikasi mobile manajemen keuangan dan pengeluaran yang mengutamakan privasi (*local-first*), dibangun dengan menggunakan Flutter. Didesain dengan estetika premium dan animasi mikro (*micro-animations*) yang halus, aplikasi ini membantu Anda mengelola keuangan harian, melacak berbagai rekening, dan menganalisis kebiasaan pengeluaran Anda—semuanya dilakukan sepenuhnya secara *offline*.

## ✨ Fitur Utama
- **Privasi (Lokal)**: Semua data tersimpan di HP (SQLite). Cadangan Google Drive opsional ke folder khusus Artavia dan bisa dikunci kata sandi (AES-256-GCM).
- **Catat cepat**: Satu layar papan angka untuk pengeluaran, pemasukan, dan transfer, dengan + − × ÷, 10 kategori tersering, dan rekening terakhir.
- **Transfer yang ingat biaya admin**: Biaya per pasangan rekening dipilih otomatis, bisa dipotong dari saldo asal atau dari uang diterima, dan dicatat sebagai pengeluaran "Biaya admin".
- **Transaksi, Laporan, Rekening, Pengaturan**: Ringkasan periode dengan insight mingguan, kartu anggaran, dan daftar per hari; laporan minggu/bulan/tahun dengan grafik tren dan donat kategori; rekening per kelompok dengan kekayaan bersih dan arsip.
- **Anggaran, Cari, Kalender**: "Perlu perhatian" dan "Aman" dengan batas aman harian, saran ejaan saat mencari, dan kalender bertitik pemasukan/pengeluaran.
- **107 ikon, 12 warna**: Kategori memakai ikon Lucide dalam 13 kelompok, bisa diurutkan dan diarsipkan.
- **Urungkan & privasi**: Hapus bisa diurungkan 5 detik; satu ketukan menyembunyikan semua nominal.
- **Excel & CSV**: Ekspor per lembar, impor 3 langkah dengan deteksi duplikat dan pembatalan 7 hari.
- **Desain "Kobalt"**: Tema gelap, terang, atau ikuti sistem, permukaan kaca, ukuran teks hingga 150 %, PIN dengan sidik jari.

## 🛠️ Teknologi yang Digunakan
- **Framework**: [Flutter](https://flutter.dev/)
- **Manajemen State & Routing**: [GetX](https://pub.dev/packages/get)
- **Database Lokal**: [sqflite](https://pub.dev/packages/sqflite)
- **Arsitektur**: Feature-Based Architecture

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

## 📝 Lisensi
Proyek ini bersifat *open-source*. Silakan di-*fork* dan dimodifikasi sesuai kebutuhan!
