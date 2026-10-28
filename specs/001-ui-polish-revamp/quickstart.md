# Quickstart: verify the revamp

```bash
flutter pub get
flutter analyze          # expect: No issues found
flutter test             # unit tests for finance_calc, period, recurring, csv, pin, currency
flutter run              # Android device/emulator
```

Color audit (SC-001) — must return no matches outside `lib/widgets/commons/colors.dart`:

```bash
grep -rnE "Colors\.(white|black|grey|red|green|blue|orange|amber|yellow|teal|purple|pink|cyan|brown|indigo|lime)|Color\(0x" lib --include=*.dart
```

## Manual walk-through (Android)

1. Fresh install → coachmark → create account → Riwayat shows calm palette, no Buku Kas icon.
2. Generate dummy data (debug only) → tabs Riwayat / Grafik / Aset / Saya: Kekayaan Bersih identical in Aset and Saya.
3. Mark one account "exclude" → both screens update equally.
4. Grafik: Pekan ‹ › navigates; Tahun shows 12 points; tap category → Indonesian dates → tap item opens detail.
5. Change month in Riwayat → Grafik (Bulan) and Anggaran show same month.
6. Cari: filter Transfer shows only transfers; asset-icon categories show icons; delete an item → list updates.
7. Detail of a transfer → Edit → Transfer form prefilled → change amount → only one transfer exists, balances correct. Delete a transfer with admin fee → balances restored.
8. Delete all accounts → tap + → "Buat rekening terlebih dahulu" state, no crash.
9. Pengaturan:
   - Pengingat Harian on, time = now+2 min → notification arrives with app closed.
   - Transaksi Berulang: monthly rule starting 2 months ago → reopen app → 2–3 tx created once; reopen → no duplicates.
   - Mulai Bulan Pada = 25 → Riwayat "Okt" covers 25 Sep–24 Okt.
   - Kunci PIN on (enter twice) → background app >10 s → PIN required; 5 wrong → 30 s wait.
   - Ekspor CSV → share sheet; Reset; Impor that file → same counts/totals.
   - Format Angka = 1,000 → all amounts use commas.
   - Efek Suara on → chime on save.
   - Cadangkan Data → lands on Saya → Cloud Backup.
10. Create budget below current spending → Riwayat budget card shows over; add expense in that category → warning toast.
11. Release build (`flutter run --release`) → no Developer menu.
