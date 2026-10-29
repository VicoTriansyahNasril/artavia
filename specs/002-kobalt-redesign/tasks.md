# Tasks: Kobalt Redesign — Tampilan, Flow & Komponen

**Input**: `specs/002-kobalt-redesign/` — plan.md, spec.md, research.md (R1–R18), data-model.md, contracts/, quickstart.md
**Tests**: included only for pure logic and migration (constitution Quality Gates: "pure logic SHOULD be covered by unit tests"); UI verified via quickstart.md.
**Conventions**: absolute imports `package:artavia/...`; every color from `colors.dart`; every mutation via `TransactionStore`/`DatabaseHelper` then `refreshAllGlobalData()`; UI copy Bahasa Indonesia; `dart format` + `flutter analyze` clean at each checkpoint.

## Format: `[ID] [P?] [Story] [FR-###] Description`

---

## Phase 1: Setup

- [X] T001 Add `lucide_icons_flutter`, `archive`, `xml`, `local_auth`, `connectivity_plus` and remove `audioplayers` in `pubspec.yaml`; run `flutter pub get`
- [X] T002 [P] Add Plus Jakarta Sans Regular/Medium/SemiBold/Bold TTF + `OFL.txt` to `assets/fonts/plus_jakarta_sans/` and declare the `fonts:` family (weights 400/500/600/700) in `pubspec.yaml`
- [X] T003 [P] Add Android `USE_BIOMETRIC` permission + `FlutterFragmentActivity` requirement for `local_auth` in `android/app/src/main/AndroidManifest.xml` and `android/app/src/main/kotlin/**/MainActivity.kt`; add `NSFaceIDUsageDescription` to `ios/Runner/Info.plist`
- [X] T004 [P] Create test folder `test/kobalt/` with a shared `sqflite_common_ffi` helper `test/kobalt/db_test_helper.dart`

---

## Phase 2: Foundational (blocks every story)

### Bolt F1 — Tokens & theme
- [X] T005 [FR-001] Rewrite `lib/widgets/commons/colors.dart`: `AppPalette` class with `AppPalette.dark` / `AppPalette.light` (all digest tokens incl. surfaceSelected, keyOperator, switchOff, scrim, accentSoft, onAccent, glass levels, category palette dark/light with soft alpha 14 %/12 %); keep public names (`colorBackground`, `colorCard`, `colorSurface`, `colorDivider`, `colorText`, `colorGrey`, `colorAccent`, `colorAccentDim`, `colorOnAccent`, `colorIncome`, `colorExpense`, `colorWarning`, `colorScrim`, `categoryPalette`, `paletteColorAt`) as getters reading `ThemeService.to.palette`; add `nearestPaletteColor(int colorVal)`
- [X] T006 [FR-001] Create `lib/widgets/commons/text_styles.dart` with `AppText` scale (display 34/40, title1 22/28, title2 20/26, title3 16/22, body 15/20, bodySmall 14/20, label 13/18, caption 12/16, amount 28/34 & 36/44 letter-spacing −0.5) all with `FontFeature.tabularFigures()`; export it from `lib/widgets/commons/common.dart`
- [X] T007 [FR-031] Create `lib/core/services/theme_service.dart` per contracts/services.md (`ThemePref`, `TextScalePref`, `reduceTransparency`, persisted via `SettingsService` keys `theme_mode`, `text_scale`, `reduce_transparency`; `setTheme` calls `Get.changeThemeMode` + `Get.forceAppUpdate()`; listens to platform brightness)
- [X] T008 [FR-001][FR-031][FR-028] Refactor `lib/main.dart`: register `ThemeService` before `runApp`; `buildAppTheme(AppPalette)` producing dark and light `ThemeData` (fontFamily `Plus Jakarta Sans`, colorScheme, dialog/sheet/datepicker themes from tokens); `GetMaterialApp(theme, darkTheme, themeMode)`; builder wraps `LockOverlay` in `MediaQuery(textScaler: ...)` from `ThemeService`; status/nav bar icon brightness follows theme
- [X] T009 Remove `const` wherever it now wraps a color getter across `lib/` (iterate `flutter analyze` until 0 errors); no behavioural change
- [X] T010 [P] Extend `lib/core/services/settings_service.dart` with keys + typed getters/setters: `hide_on_open`, `haptics`, `last_account_id`, `recent_searches`, `backup_auto`, `backup_wifi_only`, `backup_locked`, `backup_hint`, `last_backup_at`, `last_backup_bytes`, `last_backup_tx`; migrate `sound_effect` → `haptics`

### Bolt F2 — Data layer v12
- [X] T011 [FR-025][FR-026][FR-020][FR-034] Bump `lib/core/database/database_helper.dart` to version 12: `onCreate` + `onUpgrade(<12)` adding `transactions.import_batch_id` (FK ON DELETE SET NULL) & `updated_at` (backfill = date), `categories.icon_key/sort_order/is_archived`, `accounts.icon_key/sort_order/is_archived/credit_limit/due_day`, table `import_batches`; seed categories with `icon_key`; snap legacy `color_val` to `nearestPaletteColor`
- [X] T012 [FR-025] Create `lib/widgets/commons/icon_registry.dart`: 107 Lucide entries (71 base + 36 extra) in the 13 board groups with Indonesian labels (names from `inputs/01-komponen-ikon.png`), `byKey`, `search`, `legacyToKey` mapping every existing `assets/**` icon path and Material code point used in seeds/dummy data
- [X] T013 Populate `icon_key` for existing rows during the v12 upgrade via `IconRegistry.legacyToKey` in `lib/core/database/database_helper.dart`; update `transactionSelect` to also return `c.icon_key as categoryIconKey`, `c.is_archived`
- [X] T014 [P] Update `lib/core/models/account_model.dart`, `lib/model/transaction_model.dart`, `lib/core/database/dummy_data.dart` for new fields (`iconKey`, `sortOrder`, `isArchived`, `creditLimit`, `dueDay`, `importBatchId`, `updatedAt`)
- [X] T015 [P] Write `test/kobalt/migration_v12_test.dart` (v11 fixture → v12: columns exist, icon_key filled, balances unchanged) and `test/kobalt/icon_registry_test.dart` (107 unique keys, 13 groups, every legacy seed maps)
- [X] T016 [P] Write `test/kobalt/palette_test.dart`: dark/light token presence and text contrast ≥ 4.5:1 on card (NFR-001)

### Bolt F3 — Kobalt component kit
- [X] T017 [FR-002][FR-004] Create `lib/widgets/kobalt/app_scaffold.dart` (title, leading back/close, actions, orb) and `ambient_orb.dart` (RadialGradient, hidden when reduceTransparency)
- [X] T018 [P] [FR-002][FR-004] Create `lib/widgets/kobalt/glass_card.dart` with ultra/tipis/reguler/tebal levels + solid fallback
- [X] T019 [P] [FR-002][FR-005] Create `lib/widgets/kobalt/k_button.dart` (primary/tonal/text/danger, 48/40, disabled 40 %), `k_chip.dart`, `k_segment.dart`
- [X] T020 [P] [FR-002] Create `lib/widgets/kobalt/k_field.dart` (normal/active/error/warning + helper), `k_controls.dart` (KSwitch 52×32, KCheck 22, KRadio 20, KProgress)
- [X] T021 [P] [FR-002][FR-025] Create `lib/widgets/kobalt/category_icon.dart` (iconKey + color, sizes 28–64) and `list_group.dart` (`ListGroup`, `NavRow`)
- [X] T022 [P] [FR-002] Create `lib/widgets/kobalt/tx_row.dart` (64 h, wrapping title, FittedBox amount, subtitle `Kategori · Rekening · jam`) and `balance_hero.dart`, `stat_tiles.dart`, `empty_state.dart`, `step_header.dart`
- [X] T023 [FR-002][FR-007] Create `lib/widgets/kobalt/keypad.dart` (5×4 grid, operators on keyOperator, C, 000, ⌫, Simpan spanning rows 2–4, row height 52/56, haptic hook)
- [X] T024 [FR-002][FR-015] Rework `lib/widgets/components/app_feedback.dart` to Kobalt: `undo(message, onUndo, 5s)` with 3 px progress, `toast(icon, title, body, actions)`, `confirm(icon?, title, body, infoBox?, safeAction, dangerAction?, cancel)` with 55 % scrim; keep `success/info/warning/error` signatures
- [X] T025 [P] [FR-016] Create `lib/core/services/privacy_service.dart` and make `formatRupiah` in `lib/core/utils/currency_format.dart` maskable with U+2212 minus; register in `lib/main.dart`
- [X] T026 [P] [FR-030] Create `lib/core/services/haptics_service.dart` (selectionClick / lightImpact gated by setting); delete `lib/core/services/sound_service.dart` and replace its call sites

### Bolt F4 — Navigation shell
- [X] T027 [FR-003] Create `lib/widgets/kobalt/k_bottom_nav.dart` (84 h glass reguler, Transaksi · Laporan · [Catat 52 px raised 12] · Rekening · Pengaturan, active pill)
- [X] T028 [FR-003] Rewrite shell in `lib/page/home/home_screen.dart` + `home_controller.dart`: `IndexedStack` [HistoryView, ReportScreen, AccountListView, SettingsScreen], `KBottomNav`, Catat opens `addTransactionRoute`; drop old `_BottomNav`/FAB; update `lib/page/routes.dart`

**Checkpoint F**: app runs on new tokens (dark/light), font, nav shell; analyze 0 issues; migration test green.

---

## Phase 3: User Story 1 — Fondasi visual & navigasi (P1) 🎯

**Goal**: every existing screen visually on Kobalt tokens/components. **Independent test**: quickstart steps 1–3.

- [X] T029 [US1][FR-001][FR-002] Replace ad-hoc `TextStyle`/`Container` styling with `AppText` + Kobalt kit in `lib/widgets/transaction/transaction_item.dart` (delegate to `TxRow`), `lib/widgets/components/menu_group.dart` (delegate to `ListGroup`/`NavRow`), `lib/widgets/components/type_switcher.dart` (delegate to `KSegment`)
- [X] T030 [US1][FR-004] Add Kurangi transparansi switch handling to `GlassCard`/`AmbientOrb`/`KBottomNav` via `ThemeService.reduceTransparency` (and auto-fallback flag for low-end devices)
- [X] T031 [US1][FR-005] Audit touch targets (≥ 44) and min text (≥ 12) in `lib/widgets/kobalt/*`; add `Semantics` labels for every icon-only control per contracts/components.md
- [X] T032 [US1][FR-001] Add grep gate test `test/kobalt/no_hardcoded_colors_test.dart` failing on `Color(0x` / `Colors.` (except `transparent`) outside `lib/widgets/commons/colors.dart` (SC-008)

**Checkpoint US1**: all tabs render with Kobalt kit; SC-008 gate green.

---

## Phase 4: User Story 2 — Catat dengan papan angka (P1) 🎯 MVP

**Goal**: board Catat screen. **Independent test**: quickstart step 4.

- [X] T033 [P] [US2][FR-007][FR-008] Create pure `lib/core/utils/calc_engine.dart` (tokens, × ÷ precedence, ÷ round half-up, trailing operator ignored, `expression` with thousand dots, `isValid` > 0)
- [X] T034 [P] [US2] Write `test/kobalt/calc_engine_test.dart` (45.000+12.500=57.500, 45.000−50.000 invalid, 100÷3=33, trailing operator, C, ⌫, 000)
- [X] T035 [US2][FR-007][FR-008][FR-010] Refactor `lib/page/add_transaction/add_transaction_controller.dart` to use `CalcEngine`; default account = `last_account_id`, date = today; persist `last_account_id` on save; save disabled when invalid; haptics on key/save
- [X] T036 [US2][FR-009] Add top-10 most-used categories per type (count over transactions, non-archived, tie → sort_order) and "Lihat semua" bottom sheet with full grid in `add_transaction_controller.dart`
- [X] T037 [US2][FR-006][FR-007][FR-008][FR-009][FR-010] Rebuild `lib/page/add_transaction/add_transaction_screen.dart` per board: × close, `KSegment` Pengeluaran/Pemasukan/Transfer, expression + big amount (red + error text when invalid), category grid 5×2 with accent ring, glass tipis bottom sheet with account & date pickers, note field, `Keypad`
- [X] T038 [US2][FR-006] Keep typed amount when switching segment (shared amount state passed to transfer section); edit mode from Detail preloads values
- [X] T039 [US2] Call `refreshAllGlobalData()` after save and return to origin tab; success haptic

**Checkpoint US2 (MVP part 1)**: record expense/income via keypad end-to-end.

---

## Phase 5: User Story 3 — Transfer dengan biaya admin diingat (P1) 🎯 MVP

**Goal**: board Transfer. **Independent test**: quickstart step 5.

- [X] T040 [P] [US3][FR-011][FR-012][FR-013] Create pure `lib/core/utils/transfer_math.dart` (`TransferMath.preview`, `TransferFeeMemory` read/write via settings `transfer_fee:<from>:<to>`, `quickChips`)
- [X] T041 [P] [US3] Write `test/kobalt/transfer_math_test.dart` (Pengirim/Penerima deltas, fee ≥ amount invalid, shortfall 582.500 case, chips dedupe)
- [X] T042 [US3][FR-011][FR-012][FR-013] Refactor `lib/page/transfer/transfer_controller.dart`: use `TransferMath`, preselect remembered fee on pair change & swap, `activeField` amount|fee for keypad, save writes memory, fee > 0 recorded as "Biaya admin" expense via `TransactionStore`, from ≠ to enforced in picker
- [X] T043 [US3][FR-011][FR-012][FR-013] Rebuild transfer UI as the Transfer segment of Catat (new widget `lib/page/transfer/transfer_section.dart`; delete standalone layout in `transfer_screen.dart`, keep route redirecting to Catat with Transfer selected): Dari/Ke card with balances + swap button, amount `KField` (active / warning ring), Biaya admin chips (history icon, Isi sendiri → inline field), Dipotong dari segment, live summary + warning line, date + note row, `Keypad`

**Checkpoint P1 complete (MVP)**: US1–US3 shippable.

---

## Phase 6: User Story 4 — Beranda, detail, privasi, urungkan (P2)

**Independent test**: quickstart step 6.

- [X] T044 [P] [US4][FR-014] Add `weeklyInsight()` and per-period summary helpers to `lib/core/utils/finance_calc.dart`; test in `test/finance_calc_test.dart`
- [X] T045 [US4][FR-015] Extend `lib/core/database/transaction_store.dart`: `deleteTransactionById` returns snapshot, `restoreTransaction(snapshot)` (same id, re-apply balances), `duplicateToToday(id)`; set `updated_at` on insert/replace; add tests in `test/kobalt/transaction_store_test.dart`
- [X] T046 [US4][FR-014][FR-016][FR-018] Update `lib/page/home/home_controller.dart`: greeting by time, period nav, filter chips state, day groups with daily totals, first-account form state & create, remove `hideBalance` in favour of `PrivacyService`
- [X] T047 [US4][FR-014][FR-016][FR-018] Rebuild `HistoryView` in `lib/page/home/home_screen.dart`: header (Cari, Kalender, eye with pressed state), `BalanceHero` (sisa, pemasukan/pengeluaran, insight), budget card (%, progress, near-limit warning) linking to Anggaran, filter chips, day sections with `TxRow`; new-user welcome card + first-account form; Catat blocked until an account exists
- [X] T048 [US4][FR-017][FR-015] Rebuild `lib/page/transaction_detail/transaction_detail_screen.dart` per board (64 px icon, name, big amount, type pill, Rincian list, Anggaran kategori card, Jadikan berulang → recurring form prefilled, Duplikat ke hari ini, Hapus → `AppFeedback.undo` with restore)
- [X] T049 [US4][FR-016] Apply `formatRupiah(maskable)` in every amount display: home, report, accounts, budget, detail, calendar, search

---

## Phase 7: User Story 5 — Laporan, Rekening, Anggaran, Cari, Kalender (P2)

### Bolt 5a — Laporan
- [X] T050 [US5][FR-019] Merge `lib/page/chart/chart_controller.dart` logic into `lib/page/report/report_controller.dart`: range Minggu/Bulan/Tahun, period nav, expense↔income, compare vs previous period, trend bars (6 months / 7 days / 12 months; current highlighted; future dashed), donut top-5 + Lainnya, category breakdown with relative bars & counts
- [X] T051 [US5][FR-019][FR-016] Rebuild `lib/page/report/report_screen.dart` per board (segment, ‹ period ›, glass total card with type chip, bar chart, donut + legend, breakdown list, privacy note, empty period state); delete `lib/page/chart/` and its route/binding

### Bolt 5b — Rekening
- [X] T052 [P] [US5][FR-020] Add `accountGroup(type)` and single `netWorth()` (assets − |liabilities|, excluding excluded/archived) to `lib/core/utils/finance_calc.dart`; reuse everywhere net worth appears
- [X] T053 [US5][FR-020][FR-021] Update `lib/page/account_management/account_management_controller.dart`: grouped & collapsible lists with subtotals, archive/unarchive, archived count, delete flow with `AppFeedback.confirm` (Arsipkan primary, Hapus beserta N transaksi danger via `TransactionStore`, Batal); credit card limit/due fields
- [X] T054 [US5][FR-020] Create `AccountListView` (tab body) in `lib/page/account_management/account_management_screen.dart` per board (header eye + add, Kekayaan bersih hero, group headers, rows, "N rekening diarsipkan") and restyle `add_account_screen.dart` with Kobalt kit + `IconRegistry`

### Bolt 5c — Anggaran, Cari, Kalender
- [X] T055 [P] [US5][FR-022] Add `budgetStatus()`, `safeDailySpend()`, `budgetSuggestions(3 months, round up 50.000)` to `lib/core/utils/finance_calc.dart` with tests
- [X] T056 [US5][FR-022] Rebuild `lib/page/budget/budget_screen.dart` + controller: hero (sisa, dari, hari lagi, progress, aman per hari), Perlu perhatian / Aman groups, empty state with Buat anggaran + Saran (Pakai)
- [X] T057 [P] [US5][FR-023] Create `lib/core/utils/text_match.dart` (Levenshtein ≤ 2 suggestion) with test; extend `DatabaseHelper.searchTransactions` to match account name
- [X] T058 [US5][FR-023] Rebuild `lib/page/search/search_screen.dart` + controller: focused field with clear, filter chips (periode/jenis/rekening), count + total, day groups with highlighted matches, recent searches (max 5, Hapus semua), Cari per kategori chips, no-result state with suggestion + Cari di semua periode
- [X] T059 [US5][FR-024] Rebuild `lib/page/calendar/calendar_screen.dart` per board (Hari ini chip, glass month summary, grid with grey/green dots + legend, selected-day list)

---

## Phase 8: User Story 6 — Kategori (P2)

- [X] T060 [US6][FR-026][FR-021] Update `lib/page/category_management/category_management_controller.dart`: per-type list ordered by `sort_order`, reorder persist, archive/unarchive, counts & budget subtitle, delete with archive-first confirm
- [X] T061 [US6][FR-026] Rebuild `category_management_screen.dart` per board (segment with counts, Tambah kategori tonal button, hint text, `ReorderableListView` with ⠿ handles, archived link)
- [X] T062 [US6][FR-025] Rebuild `add_category_screen.dart` per board (× close, live preview glass card, name ≤ 30, type segment, 12 color radios, icon group chips + 6-col grid, "Cari dari 107 ikon" search sheet, sticky Simpan kategori); save `icon_key`

---

## Phase 9: User Story 7 — Pengaturan, ukuran teks, PIN (P3)

- [X] T063 [US7][FR-027][FR-030][FR-031] Merge `lib/page/profile/` into `lib/page/settings/settings_screen.dart` + controller as the Pengaturan tab: data-status glass card (last backup + Cadangkan sekarang), groups Keuangan (with counts), Tampilan (Tema picker, Ukuran teks, Kurangi transparansi, Awal bulan, Mata uang), Keamanan & data (Kunci aplikasi, Sembunyikan saldo saat dibuka, Cadangan Google Drive, Ekspor & impor), Lainnya (Getaran, Tentang), Reset seluruh data; keep debug tools under `kDebugMode`; delete `lib/page/profile/`
- [X] T064 [US7][FR-028] Create `lib/page/text_size/text_size_screen.dart` + controller + binding + route (system switch, slider 90–150 %, preview hero + long row, Kembalikan ke 100 %)
- [X] T065 [US7][FR-029] Extend `lib/core/services/pin_lock_service.dart` with `remainingAttempts`, `canUseBiometrics`, `unlockWithBiometrics` (`local_auth`)
- [X] T066 [US7][FR-029] Rebuild `lib/page/pin/pin_screen.dart`, `pin_pad.dart`, `lock_overlay.dart` per board (centered orb, lock tile, 6 dots red on error, message with remaining attempts, round 72 px keys, fingerprint key when available, Lupa PIN? sheet explaining Drive recovery)
- [X] T067 [US7][FR-005] Verify 150 % text scale on Transaksi, Catat, Transfer, Laporan, Rekening, Pengaturan; fix overflow with `Flexible`/`FittedBox` (SC-006)

---

## Phase 10: User Story 8 — Cadangan Drive terenkripsi (P3)

- [X] T068 [P] [US8][FR-033] Create pure `lib/core/services/backup_codec.dart` implementing contracts/backup-file-format.md (PBKDF2-HMAC-SHA256 210k + AES-256-GCM via `cryptography`); uniform `WrongPassword`
- [X] T069 [P] [US8] Write `test/kobalt/backup_format_test.dart` (locked/unlocked round-trip, wrong password, tampered tag, legacy v0)
- [X] T070 [US8][FR-032][FR-033] Create `lib/core/services/backup_service.dart` (scope `drive.appdata`, `backupNow` with progress & cancel, keep newest 5, appProperties metadata, `list`, `restore` with integrity_check + DB reopen + `refreshAllGlobalData()`, legacy root-file restore, `maybeAutoBackup` on start/resume with `connectivity_plus` Wi-Fi rule); slim `google_drive_service.dart` to auth only
- [X] T071 [US8][FR-032][FR-033] Create `lib/page/backup/backup_screen.dart` + controller + binding + route: disconnected (benefits, access note, Hubungkan / Nanti saja), connected (account + Ganti, status hero, settings rows incl. password set/hint dialog, history with Pulihkan, Putuskan), running (progress %, Batalkan); truthful auto-backup copy
- [X] T072 [US8][FR-033] Create `lib/page/backup/restore_found_screen.dart`: shown on first launch with no local data when a Drive backup exists for the signed-in account; info rows, Pilih cadangan lain (n), password field with hint on error, Pulihkan data, Mulai dari awal
- [X] T073 [US8][FR-032] Show `AppFeedback.toast` "Cadangan gagal" with Tutup / Coba lagi on backup failure (manual & auto)

---

## Phase 11: User Story 9 — Ekspor & impor (P3)

### Bolt 9a — Export
- [X] T074 [US9][FR-034] Create `lib/core/services/xlsx_codec.dart` (archive + xml, R8) and `lib/core/services/export_service.dart` (xlsx sheets Transaksi/Rekening/Kategori/Anggaran, numeric amounts, `dd/MM/yyyy`; CSV transactions-only with same headers; period filter; share via `share_plus`); delete `lib/core/services/csv_service.dart` and migrate `test/csv_test.dart`
- [X] T075 [US9][FR-034] Create `lib/page/data_transfer/export_screen.dart` + controller + binding + route (Ekspor/Impor tabs, format cards, period chips, content checkboxes with counts, preview table, sticky Ekspor N transaksi)

### Bolt 9b — Import
- [X] T076 [P] [US9][FR-035] Create `lib/core/services/import_service.dart`: `parse` in isolate (20 MB / 50 000 rows caps), `guessMapping` (header synonyms), date-format & thousand-separator detection, `preview` (ready/duplicates/invalid with reasons/new categories & accounts)
- [X] T077 [P] [US9] Write `test/kobalt/import_preview_test.dart` (31/02 invalid, empty amount, "1.2.000", sign → type, duplicate detection, re-import Artavia export = all duplicates)
- [X] T078 [US9][FR-034][FR-035] Add `TransactionStore.importBatch` (safety DB copy, single DB txn, creates `import_batches` row) and `cancelImport(keepEdited)` with 7-day rule
- [X] T079 [US9][FR-034][FR-035] Create `lib/page/data_transfer/import_screen.dart` (step 1: dropzone, Dari HP / Dari Drive, what can be imported, template download, safety note), `import_mapping_screen.dart` (step 2: file card, mapping rows with required badges & checks, detection summary, Lanjut tinjau disabled until required mapped), `import_review_screen.dart` (step 3: StatTiles, problem rows + Unduh daftar, new category/account resolution dropdowns, undo note, Impor N transaksi) + controller + routes
- [X] T080 [US9][FR-034] Create `lib/page/data_transfer/import_history_screen.dart` (list with Batalkan / expired / cancelled states; confirm dialog with edited-rows warning: Batalkan N, Batalkan simpan yang diubah, Tutup)

---

## Phase 12: Polish & cross-cutting

- [X] T081 [P] Remove unused legacy PNG icon folders under `assets/` and their `pubspec.yaml` entries; remove unused `AppIcons` lists
- [X] T082 [P] Copy pass on all strings in `lib/widgets/commons/strings.dart` and screens against the board (Bahasa Indonesia, "kamu", U+2212) (NFR-006)
- [X] T083 [P] Performance check with 5 000 dummy transactions: tab switch & post-save refresh < 300 ms; scrolling ≥ 55 fps with glass (NFR-003, NFR-004); index `transactions(date)` if needed
- [X] T084 Update `README.md` / `README_id.md` feature list and screenshots section; update `CODING_STYLE.md` color/text/component guidance to the Kobalt kit
- [X] T085 Run `dart format lib test`, `flutter analyze` (0 issues), `flutter test`; walk `quickstart.md` steps 1–11 in dark and light themes

---

## Requirement Coverage

| FR | Tasks | FR | Tasks |
|---|---|---|---|
| FR-001 | T005 T006 T008 T029 T032 | FR-019 | T050 T051 |
| FR-002 | T017–T024 T029 | FR-020 | T011 T052–T054 |
| FR-003 | T027 T028 | FR-021 | T053 T060 |
| FR-004 | T017 T018 T030 | FR-022 | T055 T056 |
| FR-005 | T019 T031 T067 | FR-023 | T057 T058 |
| FR-006 | T037 T038 | FR-024 | T059 |
| FR-007 | T023 T033 T035 T037 | FR-025 | T011 T012 T021 T062 |
| FR-008 | T033 T035 T037 | FR-026 | T011 T060 T061 |
| FR-009 | T036 T037 | FR-027 | T063 |
| FR-010 | T035 T037 | FR-028 | T008 T064 |
| FR-011 | T040 T042 T043 | FR-029 | T065 T066 |
| FR-012 | T040 T042 T043 | FR-030 | T026 T063 |
| FR-013 | T040 T042 T043 | FR-031 | T007 T008 T063 |
| FR-014 | T044 T046 T047 | FR-032 | T070 T071 T073 |
| FR-015 | T024 T045 T048 | FR-033 | T068 T070–T072 |
| FR-016 | T025 T046 T047 T049 T051 | FR-034 | T011 T074 T075 T078–T080 |
| FR-017 | T048 | FR-035 | T076 T078 T079 |
| FR-018 | T046 T047 | | |

NFR-001 T016 · NFR-002 T037 · NFR-003/004 T083 · NFR-005 T070 (Drive only) · NFR-006 T082 · NFR-007 T031.

## Dependencies & Execution Order

```text
Setup (T001–T004)
  └─▶ Foundational F1 → F2 → F3 → F4 (T005–T028)   ← blocks all stories
        ├─▶ US1 (T029–T032)
        ├─▶ US2 (T033–T039) ─▶ US3 (T040–T043)       [US3 hosted inside Catat]
        ├─▶ US4 (T044–T049)  (needs T045 store ext.)
        ├─▶ US5 (T050–T059)
        ├─▶ US6 (T060–T062)
        ├─▶ US7 (T063–T067)
        ├─▶ US8 (T068–T073)  (T063 data-status card links here)
        └─▶ US9 (T074–T080)  (T079 depends on T076, T078)
  └─▶ Polish (T081–T085) after all stories
```

## Parallel Examples

- F3: T018, T019, T020, T021, T022 together (separate files).
- US2/US3 logic: T033+T034 and T040+T041 in parallel before the screens.
- US5: T052, T055, T057 (pure helpers) in parallel; then screens.
- US8/US9: T068+T069 and T076+T077 in parallel.

## Implementation Strategy

1. **MVP** = Setup + Foundational + US1 + US2 + US3 (T001–T043): new look, nav, Catat & Transfer. Stop, run quickstart 1–5.
2. **Increment 2** = US4 + US5 + US6 (daily views).
3. **Increment 3** = US7 (settings/security).
4. **Increment 4** = US8 + US9 (data features).
5. Polish. Commit per Bolt with Conventional Commits.
