# Artavia - Pencatat Keuangan 💸

*Baca ini dalam bahasa lain: [English](README.md) | [Bahasa Indonesia](README_id.md)*

> **🚧 Status Pengembangan: Aktif Dikembangkan**  
> *Proyek ini saat ini masih dalam tahap pengembangan aktif. Fitur, antarmuka (UI), dan struktur database dapat berubah sewaktu-waktu. Segala bentuk masukan (feedback) sangat diharapkan!*

Artavia adalah aplikasi mobile manajemen keuangan dan pengeluaran yang mengutamakan privasi (*local-first*), dibangun dengan menggunakan Flutter. Didesain dengan estetika premium dan animasi mikro (*micro-animations*) yang halus, aplikasi ini membantu Anda mengelola keuangan harian, melacak berbagai rekening, dan menganalisis kebiasaan pengeluaran Anda—semuanya dilakukan sepenuhnya secara *offline*.

## ✨ Fitur Utama
- **Utamakan Privasi (Lokal)**: Semua data tersimpan di perangkat (SQLite), tanpa pelacakan. Cadangan Google Drive bersifat opsional dan hanya berjalan saat Anda memintanya.
- **Manajemen Multi-Rekening & Transfer**: Dompet, bank, dan uang digital, termasuk transfer dengan biaya admin.
- **Analisis dalam Satu Tempat**: Ringkasan, pengeluaran per kategori, dan tren mingguan/bulanan/tahunan di tab Grafik; kekayaan bersih di tab Aset.
- **Anggaran**: Batas per kategori dengan ringkasan di Riwayat dan peringatan saat melewati batas.
- **Transaksi Berulang**: Gaji, sewa, atau langganan tercatat otomatis.
- **Pengaturan Lengkap**: Pengingat harian, kunci PIN, awal bulan kustom, format angka, efek suara, serta ekspor/impor CSV.
- **Tampilan Kalem**: Mode gelap dengan palet "slate" yang lembut dan kontras terukur agar nyaman di mata.

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
