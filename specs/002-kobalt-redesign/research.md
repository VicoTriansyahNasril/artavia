# Research: Kobalt Redesign

Phase 0 output for [plan.md](plan.md). Each item: Decision · Rationale · Alternatives.

## R1. Dark + light themes with the existing top-level color constants

- **Decision**: Introduce an `AppPalette` value class with `AppPalette.dark` and `AppPalette.light`
  (all tokens from the digest). Keep the existing public names (`colorBackground`, `colorCard`,
  `colorText`, …) but turn them from `const Color` into top-level **getters** that read
  `ThemeService.to.palette`. Theme changes call `Get.changeThemeMode` + `Get.forceAppUpdate()` so
  every screen rebuilds with the new palette. `buildAppTheme(AppPalette p)` produces both
  `ThemeData`s.
- **Rationale**: ~70 files already use `colorX` names; getters keep every call site source-
  compatible (only `const` keywords around them must go, a mechanical change caught by the
  analyzer). One palette class = Principle III "single source of visual truth".
- **Alternatives**: `ThemeExtension` + `Theme.of(context).extension<…>()` everywhere — cleaner
  but needs a `BuildContext` at ~600 call sites, including controllers; rejected for churn.
  Dark-only — rejected by user (Q1).

## R2. Typography — Plus Jakarta Sans

- **Decision**: Bundle the four static TTFs (Regular 400, Medium 500, SemiBold 600, Bold 700;
  SIL OFL 1.1) under `assets/fonts/plus_jakarta_sans/` and declare them in `pubspec.yaml`.
  The base `TextTheme` sets `fontFeatures: [FontFeature.tabularFigures()]`. A `AppText` token set
  (display 34/40, title1 22/28, title2 20/26, title3 16/22, body 15/20, bodySmall 14/20,
  label 13/18, caption 12/16) replaces ad-hoc `TextStyle(fontSize: …)`.
- **Rationale**: offline-first (Principle I) forbids runtime font downloads; tabular figures keep
  amounts aligned as on the board.
- **Alternatives**: `google_fonts` — fetches over the network by default; rejected.

## R3. Category & account icons (107 Lucide icons)

- **Decision**: Add dependency **`lucide_icons_flutter`** (ISC licence, icon font, pure Flutter).
  Store a stable string `icon_key` (Lucide name, e.g. `utensils`) on categories and accounts. An
  `IconRegistry` lists the 107 icons as `(key, IconData, labelId, group)` in the 13 groups of the
  board, with Indonesian-label search. A migration maps every seeded `icon_path` / `icon_code`
  to the nearest Lucide key; unknown legacy icons fall back to `ellipsis` ("Lainnya").
- **Rationale**: the board explicitly specifies Lucide line icons; a font keeps the APK small and
  recolours freely (category color + 14 % fill). String keys survive package updates better than
  code points.
- **Alternatives**: copy 107 SVGs into assets (`flutter_svg` exists) — more files, manual upkeep;
  Material Icons — wrong visual language. The old PNG icon assets are removed after migration
  (YAGNI).

## R4. Glass cards and ambient orb performance

- **Decision**: `GlassCard` = `ClipRRect` + `BackdropFilter(ImageFilter.blur(20))` + tinted fill +
  1 px border + inset highlight, with four levels (ultra/tipis/reguler/tebal). The orb is a
  `RadialGradient`-filled circle (no blur filter), drawn once per screen by `AppScaffold`.
  `reduceTransparency` (setting) swaps every glass level for its solid equivalent.
- **Rationale**: blurring a gradient that is already soft costs nothing; a real blur on a large
  orb repaints every frame. BackdropFilter is limited to ≤ 3 surfaces per screen (hero card,
  bottom nav, keypad sheet / snackbar) to hold 55+ fps (NFR-004).
- **Alternatives**: blur everywhere — jank on mid-range Android; no glass — off-design.

## R5. Global privacy mode

- **Decision**: New `PrivacyService` (GetxService, `RxBool masked`) initialised from the
  `hide_on_open` setting. All amount rendering goes through `formatRupiah(..., maskable: true)`
  which returns `Rp ••••••` when masked; percentages are never masked. Replaces
  `HomeController.hideBalance`.
- **Rationale**: FR-016 requires one switch for every tab; a service is the GetX idiom.
- **Alternatives**: per-screen flags — the current bug-prone state.

## R6. Undo delete (5 s)

- **Decision**: Delete immediately through `TransactionStore.deleteTransactionById` (balances
  reverted in the same DB transaction), keep the deleted row map in memory, and show the undo
  snackbar for 5 s. "Urungkan" calls `TransactionStore.restoreTransaction(row)` which re-inserts
  the row **with its original id** and re-applies the balance effect.
- **Rationale**: no "pending delete" state in the DB → nothing dangling if the app is killed
  (spec edge case: deletion stands). Reuses Principle IV mutation paths.
- **Alternatives**: soft-delete column + delayed purge — needs every query to filter and a purge
  job; rejected.

## R7. Remembered transfer fee per account pair

- **Decision**: Store in the existing `settings` table under key
  `transfer_fee:<fromId>:<toId>` → JSON `{"fee":2500,"bearer":"source|received"}`, written on
  every transfer save. Quick chips = remembered value + {2.500, 6.500} deduplicated.
- **Rationale**: tiny key/value data; no schema change needed.
- **Alternatives**: a `transfer_fee_prefs` table — overkill.

## R8. Excel import/export

- **Decision**: Small in-house xlsx reader/writer (`lib/core/services/xlsx_codec.dart`) built on
  **`archive`** (zip) + **`xml`** (SpreadsheetML; sharedStrings + inline strings). Export writes sheets
  `Transaksi`, `Rekening`, `Kategori`, `Anggaran`; amounts stored as numbers, dates as
  `dd/MM/yyyy`. CSV export = transactions only (existing `csv_service` kept, re-headered to match).
  Import pipeline (pure, unit-tested): `parseFile → detect header / date format / thousand
  separator → ColumnMapping (auto-guess by header synonyms) → ImportPreview { ready, duplicates,
  invalid(row, reason), newCategories, newAccounts } → commit`.
  Duplicate key = same local date + type + absolute amount + account name + normalised note.
  Re-importing an Artavia export therefore yields 0 new rows (SC-007).
- **Rationale**: user chose full scope (Q3). The `excel` package (≥4.0.6) needs `archive ^3`, which
  conflicts with `archive ^4` pulled in by `flutter_native_splash` → `image`; pub cannot resolve it
  (found during T001, 2026-10-29). We only need plain cells (text, number, date), so a ~300-line codec
  is smaller than pinning old tooling.
- **Alternatives**: `excel` — dependency conflict (above); `spreadsheet_decoder` — read-only.

## R9. Import history & 7-day undo

- **Decision**: New table `import_batches`; `transactions.import_batch_id` (FK, ON DELETE SET NULL)
  and `transactions.updated_at`. Commit runs in one DB transaction after an automatic local
  safety copy of the DB file. Undo (≤ 7 days, status `active`) deletes the batch's transactions
  through the balance-reverting path; option "simpan yang diubah" skips rows whose
  `updated_at > batch.created_at`. Batches older than 7 days show as `expired`.
- **Rationale**: FR-034 / US9; Principle IV (balances stay consistent).

## R10. Encrypted Google Drive backups

- **Decision**:
  - Scope: move to `drive.appdata` (hidden app folder, "Artavia hanya bisa membuka folder
    khususnya"). On first connect after update, a legacy `artavia_backup.db` in "My Drive" (old
    scope) is still offered for restore if readable, then left untouched.
  - Files: `artavia-<yyyyMMdd-HHmm>.artv`, newest 5 kept (older deleted after a successful
    upload). Listing metadata (device, created, tx count, account count, size, locked) is stored
    in Drive `appProperties` so "Cadangan ditemukan" renders without downloading.
  - Format (see [contracts/backup-file-format.md](contracts/backup-file-format.md)): magic +
    JSON header (version, kdf params, salt, nonce, hint) + payload. Payload = SQLite file;
    when locked: AES-256-GCM with key from PBKDF2-HMAC-SHA256 (210 000 iterations, 16-byte salt)
    via the existing `cryptography` package. Password is never stored; only the hint.
    *Implementation note (2026-10-29)*: to let the daily auto-backup encrypt without asking,
    the derived 32-byte key and its salt are kept in the local `settings` table and are
    stripped from every uploaded copy, so a backup file alone still needs the password.
  - Auto backup: checked on app start/resume; runs if enabled, last success > 24 h, and (Wi-Fi only
    setting) the device is on Wi-Fi — via new dependency **`connectivity_plus`**. No background
    scheduler; the board copy "tetap jalan walau aplikasi ditutup" is changed to "berjalan saat
    aplikasi dibuka" (Principle V honest UI).
- **Rationale**: user chose password + encryption (Q2); appdata scope is least privilege.
- **Alternatives**: Argon2id — pure-Dart implementation too slow on low-end phones; background
  `workmanager` — extra native setup and battery cost, not required by any FR.

## R11. Fingerprint on the PIN screen

- **Decision**: Add dependency **`local_auth`**; the fingerprint key appears only when the device
  has enrolled biometrics. Wrong PIN shows remaining attempts (existing lockout counter in
  `PinLockService` extended to expose `remainingAttempts`).
- **Alternatives**: hide the key — the board shows it; rejected.

## R12. Text size

- **Decision**: Settings `text_scale` = `system | 0.9 | 1.0 | 1.15 | 1.3 | 1.5`. `GetMaterialApp.builder`
  wraps the app in `MediaQuery(textScaler: …)`. Rows use `Flexible` titles and
  `FittedBox(scaleDown)` amounts so 150 % never clips (SC-006).

## R13. Haptics replace sound effects

- **Decision**: The board's "Getaran" replaces the current "Efek suara" setting; implemented with
  `HapticFeedback.selectionClick()` (keypad) / `lightImpact()` (save). `SoundService` and the
  `audioplayers` dependency are removed (Principle V: prefer removing over duplicating).
- **Alternatives**: keep both toggles — not on the board; rejected.

## R14. Navigation restructure

- **Decision**: Bottom nav = Transaksi (HistoryView) · Laporan (new `ReportScreen` combining the old
  chart + report controllers into one `ReportController` with Minggu/Bulan/Tahun) · Catat ·
  Rekening (account list content from `account_management`) · Pengaturan (merged
  profile + settings). Old `ChartScreen`/`ProfileScreen` are deleted; their routes are removed.
  Budget, Kategori, Recurring, Drive, Ekspor/Impor, Ukuran teks become pushed routes.

## R15. Search suggestions & history

- **Decision**: Search matches note, category name, account name. On zero results, suggest the
  vocabulary term (category names + distinct note words) with Levenshtein distance ≤ 2.
  Last 5 queries stored as JSON in settings `recent_searches`.

## R16. Budget suggestions & safe-daily

- **Decision**: Suggestion per category = mean spend of the last 3 complete months, rounded up to
  the next Rp 50.000; shown only when ≥ 1 complete month exists. "Aman dibelanjakan per hari" =
  remaining total budget ÷ remaining days in period (min 1).

## R17. Weekly insight on the summary card

- **Decision**: Compare spending Monday→today of this week vs the same weekdays last week;
  copy "Pengeluaran minggu ini N % lebih rendah/tinggi dari minggu lalu"; hidden if last week = 0.

## R18. Security notes (backup / import — security-standard §7)

- Backup decrypt failures return one uniform message ("Kata sandi salah") — no oracle on which
  step failed. Restore replaces the DB only after the decrypted payload passes
  `PRAGMA integrity_check` on a temp copy.
- Import files are parsed in an isolate with a 20 MB cap and 50 000-row cap; cell text is never
  evaluated (formulas read as cached values).
- No new network calls besides Google Drive (Principle I).
