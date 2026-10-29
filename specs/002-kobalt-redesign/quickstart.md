# Quickstart: Verify the Kobalt Redesign

## Setup

```bash
flutter pub get
dart format lib test
flutter analyze          # must report 0 issues
flutter test             # unit tests incl. new calc/transfer/import/backup-format tests
flutter run              # on an Android device / emulator
```

Use a device with an existing v11 database first (upgrade path), then a fresh install.

## Manual verification walk-through

1. **Upgrade** — install over v11 data: categories keep names/colors (blue snaps to #5B8CFF),
   each shows a Lucide icon, balances unchanged.
2. **US1 Fondasi** — every tab uses Plus Jakarta Sans, tabular figures, glass hero + one orb.
   Bottom nav: Transaksi · Laporan · [Catat] · Rekening · Pengaturan. Toggle
   Pengaturan › Kurangi transparansi → glass becomes solid.
3. **Tema** — Pengaturan › Tema › Terang: all screens switch to the light tokens; Ikuti sistem follows
   the OS setting.
4. **US2 Catat** — Catat › type `45000 + 12500` → "Rp 57.500"; pick Makanan, Simpan → row on
   beranda, BCA −57.500. Type `45000 − 50000` → red −5.000, Simpan disabled.
5. **US3 Transfer** — BCA→GoPay 100.000, admin 2.500 dipotong dari Saldo BCA → summary line,
   save; reopen transfer BCA→GoPay → 2.500 preselected. Try "Uang diterima" with 4.000 → GoPay
   +96.000. Enter 9.000.000 → yellow warning, still saves.
6. **US4** — delete a transaction from Detail → snackbar with 5 s bar → Urungkan → row and
   balance back. Eye icon → amounts masked on Transaksi, Laporan, Rekening.
   Fresh install → "Mulai dengan satu rekening" form.
7. **US5** — Laporan Minggu/Bulan/Tahun; Rekening groups + Kekayaan bersih; delete an account with
   transactions → Arsipkan / Hapus beserta N / Batal; Anggaran groups; Cari "kopiii" → suggestion.
8. **US6** — Kategori › Tambah: preview updates with color/icon; search "kopi" in 107 icons; drag
   to reorder.
9. **US7** — Ukuran teks 150 %: no clipped text on Transaksi/Catat/Transfer. Wrong PIN → red dots +
   remaining attempts; fingerprint key on enrolled devices. Getaran toggles haptics.
10. **US8** — Drive: connect, enable password, Cadangkan sekarang (progress), list shows entry;
    reinstall → "Cadangan ditemukan" → wrong password shows hint → correct password restores.
    Airplane mode + Cadangkan → "Cadangan gagal" toast with Coba lagi.
11. **US9** — Ekspor Excel (all parts) → open in Sheets: 4 sheets, numeric amounts. Reset data,
    Impor the same file → 0 problem rows; import it again → all duplicates. Riwayat impor →
    Batalkan → transactions removed, balances restored.

## Automated checks

- `test/kobalt/palette_test.dart` — every token in digest present for dark & light; contrast ≥ 4.5:1.
- `test/kobalt/icon_registry_test.dart` — 107 unique keys, 13 groups, legacy map covers all seeds.
- `test/kobalt/calc_engine_test.dart`, `transfer_math_test.dart`.
- `test/kobalt/import_preview_test.dart` — duplicates, invalid dates, sign-based type.
- `test/kobalt/backup_format_test.dart` — encrypt/decrypt round-trip, wrong password uniform error.
- `test/kobalt/migration_v12_test.dart` — v11 fixture → v12 via sqflite_common_ffi.
- Grep gate: no `Color(0x` or `Colors.` (except transparent) outside `colors.dart`.
