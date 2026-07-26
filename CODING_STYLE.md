# Panduan Gaya Kode (Coding Style) - Artavia

Dokumen ini adalah panduan resmi penulisan kode untuk proyek **Artavia**. Mengikuti panduan ini diwajibkan bagi seluruh pengembang yang berkontribusi agar kode tetap rapi, konsisten, mudah dirawat (maintainable), dan meminimalisir bug. 

Proyek ini dibangun menggunakan **Flutter** dengan **GetX** sebagai solusi _State Management_ dan _Routing_.

---

## 1. Arsitektur dan Struktur Direktori

Proyek ini menggunakan arsitektur **Feature-Based** (berbasis fitur). Setiap fitur besar memiliki foldernya sendiri di dalam `lib/page/`.

### Struktur Dasar `lib/`:
```text
lib/
├── page/                   # Kumpulan layar dan fitur utama aplikasi
│   ├── account_management/ # Fitur Account Management
│   │   ├── account_management_screen.dart
│   │   └── account_management_controller.dart
│   ├── home/               # Fitur Home
│   │   ├── home_screen.dart
│   │   └── home_controller.dart
│   └── routes.dart         # Pusat pendaftaran rute (GetPage)
├── widgets/                # Komponen UI yang dapat digunakan kembali (reusable)
│   ├── commons/            # Resource umum, tema, konstanta, dan widget dasar
│   └── custom_button.dart  # Contoh reusable widget
└── main.dart               # Entry point aplikasi
```

### Aturan Arsitektur:
- **Pemisahan Perhatian (Separation of Concerns):** Jangan mencampur logika bisnis di dalam file UI. File `..._screen.dart` hanya bertugas menampilkan UI, sedangkan file `..._controller.dart` bertugas menangani logika, manipulasi data, dan pemanggilan API.

---

## 2. Aturan Penamaan (Naming Conventions)

Konsistensi penamaan adalah kunci. Ikuti konvensi berikut dengan ketat:

- **Classes, Enums, Typedefs, dan Extensions:** Gunakan `PascalCase`.
  ```dart
  class HomeScreen extends StatelessWidget {}
  enum TransactionType { income, expense }
  ```
- **Nama File dan Folder:** Gunakan `snake_case`. Berikan akhiran (*suffix*) sesuai dengan fungsinya.
  - Halaman/UI: `nama_fitur_screen.dart`
  - Controller (GetX): `nama_fitur_controller.dart`
  - Model data: `nama_model.dart`
- **Variabel, Fungsi, dan Parameter:** Gunakan `camelCase`.
  ```dart
  String userName = "John Doe";
  void fetchTransactionData() {}
  ```
- **Konstanta (Constants):** 
  - Gunakan `camelCase` jika merupakan konstanta spesifik untuk UI/Tema (misal: `colorBackground`).
  - Gunakan `SCREAMING_SNAKE_CASE` untuk konstanta global seperti API Key atau konfigurasi statis.
  ```dart
  const Color colorAccent = Color(0xFF123456);
  const String BASE_URL = "https://api.example.com";
  ```

---

## 3. Panduan Penggunaan GetX (State Management & Routing)

- **Routing:**
  - Daftarkan semua rute di `lib/page/routes.dart` menggunakan `GetPage`.
  - Gunakan Named Routes untuk navigasi.
    ```dart
    // ✅ Benar
    Get.toNamed('/home');
    
    // ❌ Dihindari
    Get.to(HomeScreen());
    ```
- **State Management:**
  - Jadikan tipe data sebagai _Reactive_ dengan menambahkan `.obs` hanya jika UI perlu diperbarui setiap kali nilai tersebut berubah.
  - Gunakan widget `Obx(() => ...)` untuk merender perubahan dari variabel `.obs`.
  - Jangan gunakan `Obx` secara berlebihan pada widget root (paling atas); bungkus hanya widget terkecil yang benar-benar membutuhkan pembaruan status.
- **Dependency Injection:** Gunakan `Get.put()` atau `Bindings` untuk menginisialisasi controller secara efisien sebelum halaman dirender.

---

## 4. Panduan UI dan Pembuatan Widget

- **Gunakan `const` Constructor:**
  Sangat diwajibkan untuk menambahkan `const` pada widget yang tidak berubah state-nya. Ini akan sangat meningkatkan performa (FPS) aplikasi Flutter.
  ```dart
  // ✅ Benar
  const SizedBox(height: 16);
  const Text('Halo');
  
  // ❌ Salah
  SizedBox(height: 16);
  Text('Halo');
  ```
- **Ekstrak Widget, Jangan Ekstrak Method:**
  Jika sebuah widget mulai membesar dan kompleks (lebih dari ~100 baris kode), pecah bagian tersebut menjadi Class Widget yang baru (`StatelessWidget`), jangan memecahnya menjadi sebuah fungsi yang me-return `Widget`.
  ```dart
  // ✅ Benar: Ekstrak menjadi class
  class HeaderCard extends StatelessWidget { ... }
  
  // ❌ Salah: Ekstrak menjadi method (menyebabkan build keseluruhan ulang)
  Widget _buildHeaderCard() { return Container(...); }
  ```
- **Pemanfaatan Tema (Theme):**
  Hindari melakukan _hardcode_ warna atau ukuran font langsung di dalam UI. Gunakan pengaturan tema dari `main.dart` atau konstanta dari `lib/widgets/commons/`.

---

## 5. Penulisan Kode Dart (Best Practices)

- **Null Safety:** 
  Aplikasi ini menggunakan Dart Null Safety. Hindari memaksa nilai *non-null* menggunakan operator *bang* (`!`), kecuali jika Anda 100% yakin data tersebut tidak akan pernah *null*. Manfaatkan *fallback* `??` atau lakukan _null checking_.
  ```dart
  // ✅ Benar
  String name = user?.name ?? "Guest";
  
  // ❌ Sangat rentan crash
  String name = user!.name;
  ```
- **Early Return:**
  Hindari _nested-if_ yang terlalu dalam. Gunakan pengembalian fungsi lebih awal (*early return*).
  ```dart
  // ✅ Benar
  if (data == null) return;
  // Lakukan eksekusi
  
  // ❌ Salah
  if (data != null) {
     // Lakukan eksekusi (menambah kedalaman indentasi)
  }
  ```
- **Penanganan Error:** Selalu bungkus proses krusial seperti pemanggilan API lokal/online (misal `sqflite`) dalam blok `try-catch`.

---

## 6. Aturan Import File

Urutkan blok import dengan aturan berikut:
1. `dart:...` (contoh: `dart:async`, `dart:convert`)
2. `package:flutter/...` (semua bawaan Flutter)
3. `package:...` (semua paket pihak ketiga dari pub.dev, seperti Get, Intl, Sqflite)
4. Import absolut internal proyek (`package:artavia/...`)

**Gunakan Absolute Import** untuk file dalam proyek ini.
```dart
// ✅ Benar
import 'package:artavia/page/home/home_screen.dart';

// ❌ Dihindari
import '../../home/home_screen.dart';
```

---

## 7. Formatting dan Analisis Linter

- **Linter:** Proyek ini mematuhi `flutter_lints`. Jangan menonaktifkan aturan linter tanpa alasan kuat. Gunakan terminal untuk mengecek apakah kode Anda sudah bersih dari *warnings*:
  ```bash
  flutter analyze
  ```
- **Format Otomatis:** Sebelum melakukan `git commit`, pastikan Anda telah memformat kode Anda. Gunakan opsi *Format on Save* di IDE Anda atau jalankan:
  ```bash
  dart format lib/
  ```

---

## 8. Komentar (Comments) dan Dokumentasi

- Tulis kode dengan rapi dan jelas (Clean Code) sehingga bisa menjelaskan dirinya sendiri. Penamaan variabel yang jelas lebih berharga daripada banyak komentar.
- **`//` (Single line comment):** Gunakan untuk memberi penjelasan kecil atau untuk memberi tahu **mengapa (why)** sebaris kode ditulis sedemikian rupa, bukan untuk menjelaskan **apa (what)** yang kode tersebut lakukan.
- **`///` (Documentation comment):** Gunakan untuk mendokumentasikan class, metode, atau reusable widget kompleks yang mungkin digunakan oleh pengembang lain.

---

## 9. Pesan Commit Git (Opsional namun disarankan)

Agar riwayat pengerjaan mudah ditelusuri, gunakan format *Conventional Commits*:
- `feat:` (fitur baru)
- `fix:` (perbaikan bug)
- `refactor:` (perubahan kode tanpa mengubah fungsionalitas - misal perapian kode)
- `chore:` (perubahan pada hal di luar kode produk - misal update dependency `pubspec.yaml`)
- `docs:` (perubahan pada dokumentasi / README)

**Contoh:** `feat: menambahkan fitur pencarian (search screen)`
