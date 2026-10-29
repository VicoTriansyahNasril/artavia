# Implementation Log — 002-kobalt-redesign

## Session 1 — 2026-10-29

- Base HEAD: `6390f526bc2622e79aadc6e487b7b38766935d18` (branch `main`, changes left unstaged)
- Target: MVP (T001–T043), then checkpoint with the user

### Done

| Task | Notes |
| ---- | ----- |
| T001 | Added lucide_icons_flutter, local_auth, connectivity_plus, archive, xml; removed audioplayers + `assets/sounds/`. **Deviation**: `excel` dropped (archive ^3 vs ^4 conflict) → in-house xlsx codec; research R8, plan, T074 updated |
| T002 | Plus Jakarta Sans 400/500/600/700 + OFL.txt |
| T003 | `FlutterFragmentActivity`, `USE_BIOMETRIC`, AppCompat NoActionBar parents in all `styles.xml`, appcompat dep; `NSFaceIDUsageDescription` |
| T004 | `test/kobalt/db_test_helper.dart` |
| T005 | `AppPalette.dark/light`; `colorX` getters read `AppPalette.current` (set by ThemeService) rather than `ThemeService.to.palette`, so pure-logic tests need no GetX. `nearestPaletteValue(int)` replaces the `nearestPaletteColor` name |
| T006 | `AppText` scale + `AppTextColor` extension |
| T007 | `ThemeService` (system/dark/light, text scale, reduce transparency) |
| T008 | `main.dart`: `buildAppTheme(AppPalette)` light+dark, themeMode, textScaler, system-bar sync; Theme/Privacy/Haptics services registered |
| T009 | Scripted removal of 212 enclosing `const`s + 2 default params made nullable; `flutter analyze` → 0 issues |
| T010 | New settings keys. `sound_effect` not migrated: haptics defaults to on, the old key is simply ignored |
| T012 | IconRegistry: 107 entries / 13 groups, all Lucide names verified |
| T025 | PrivacyService + `CurrencyService.money/digits/short` with U+2212 and mask |
| T026 | HapticsService; SoundService deleted; Pengaturan toggle "Efek Suara" → "Getaran" (interim until T063) |
| T011/T013 | DB v12: new columns, `import_batches`, idempotent `_backfillV12` (icon_key from legacy icons, sort_order, palette snap, `updated_at = date`) run from both `onCreate` and `onUpgrade`; `openAt()` for tests |
| T014 | Models extended. `dummy_data.dart` left unchanged — `_backfillV12` fills its rows |
| T015/T016 | migration, icon registry, palette (WCAG 4.5:1 for text and muted text, both themes) tests |
| T017–T023 | Kobalt kit in `lib/widgets/kobalt/` (+ `kobalt.dart` barrel). `CategoryIcon` stays in `commons/common.dart` (re-exported) instead of a second copy |
| T024 | `AppToast` (overlay, glass tebal, one at a time) adds `toast(...)` and `undo(...)`; `AppDialog.confirm` adds `icon`, `info`, `safeLabel`. Old signatures unchanged |
| T027/T028 | `KBottomNav` + shell. Tabs: Transaksi = HistoryView, Laporan = ChartScreen, Rekening = ReportScreen, Pengaturan = ProfileScreen (hub that links Rekening/Anggaran/Kategori/Pengaturan) until US5/US7 rebuild them. Privacy eye moved to tab header and is global (PrivacyService) |
| T029 | TransactionItem → TxRow, MenuGroup/MenuTile/MenuSwitchTile → ListGroup/NavRow/KSwitch, TypeSwitcher → KSegment |
| T030 | Reduce-transparency handled in GlassCard/AmbientOrb/KBottomNav. No automatic low-end detection (no reliable signal); the setting covers it |
| T031 | Hit areas ≥ 44 for switch/radio/check/chip; nav labels 12 px |
| T032 | `no_hardcoded_colors_test.dart` |
| T033/T034 | `CalcEngine` + tests |
| T035–T039 | Catat rebuilt; shared amount across segments; top-10 grid + "Lihat semua"; last account; account/date/note chips on the glass sheet |
| T040/T041 | `TransferMath`, `TransferFeeMemory` + tests |
| T042/T043 | Transfer is a segment of Catat (`transfer_section.dart`); `/transfer` route opens Catat on Transfer; `transfer_screen.dart` + `transfer_binding.dart` deleted. **Design decision (FR-012)**: a transfer with a fee is stored as transfer row (`amount` = received, `admin_fee` 0) + "Biaya admin" expense from the source, in one DB transaction (`saveTransfer`). Legacy rows with an embedded fee still work and are converted when edited |

### Verification

- `flutter analyze`: No issues found
- `flutter test`: 82/82 passed (incl. controller flow test on a real FFI DB and Catat render test at 360×720 / 412×915, dark + light, 3 segments)
- Not verified: running on a physical device / emulator (no device session here)

## Session 2 — 2026-10-29 (US4–US9 + Polish)

| Task | Notes |
| ---- | ----- |
| T044 | `weeklyInsight`, `budgetStatus`, `safeDailySpend`, `budgetSuggestions`, `accountGroup` in `finance_calc.dart` (+ tests). Archived accounts leave net worth |
| T045 | `deleteTransactionById` returns a snapshot; `restoreTransaction`, `duplicateToToday`; edits keep `import_batch_id` |
| T046–T048 | Home rebuilt (greeting, ‹ period ›, insight, budget card with near-limit category, filter chips, day groups with net, welcome card + first-account form; Catat blocked without an account). Coach-mark tutorials removed (welcome card replaces them). Detail rebuilt; delete = undo snackbar instead of a confirm dialog |
| T049 | Every amount goes through `CurrencyService.money/digits/short` (masked) |
| T050–T054 | `report/` is now Laporan (chart merged, `chart/` deleted); Rekening tab = `AccountListView` (groups, subtotals, archive, Arsipkan-first delete via `AppDialog.choose`); account form on the kit with Lucide icons, credit limit and due day |
| T055–T059 | Anggaran (Perlu perhatian / Aman, safe daily, 3-month suggestions + Pakai), Cari (period/type/account filters, highlight, recent, spelling via `text_match.dart`, account names searchable), Kalender (summary, dots, legend, Hari ini) |
| T060–T062 | Kategori: drag reorder (`sort_order`), archive/restore, counts + budget subtitle, Arsipkan-first delete; form with live preview, 12 colours, 107-icon picker + search |
| T063 | Pengaturan tab replaces Saya; `lib/page/profile/` deleted. Debug "data dummy" under `kDebugMode` |
| T064 | Ukuran teks screen (system switch, 90–150 %, preview) |
| T065/T066 | PIN: 6 digits for new PINs (existing 4-digit PINs keep working — length stored), remaining attempts, fingerprint via `local_auth`, "Lupa PIN?" inline (the lock sits above the navigator, so no sheets/dialogs) |
| T067 | `screens_render_test.dart`: every screen at 360×720, dark + light, 100 % + 150 % — fixed overflows in the home period row, `NavRow` trailing, Catat grid, Kalender legend, Kategori header |
| T068–T073 | `.artv` codec (PBKDF2 210k + AES-256-GCM), `BackupService` (appData, keep 5, progress/cancel, history from appProperties, restore with integrity check, auto on start/resume with Wi-Fi rule, restore offer on empty install), `GoogleDriveService` slimmed to auth. **Deviation**: derived key kept locally for auto backup (research R10 note) |
| T074–T080 | `csv_codec.dart` + `xlsx_codec.dart` (archive + xml), `export_service.dart`, `import_service.dart` (mapping, date order, thousand separator, strict dates, duplicates, new names), `importBatch` / `cancelImport(keepEdited)`, screens: Ekspor & impor, Cocokkan kolom, Tinjau, Riwayat impor. `csv_service.dart` + `test/csv_test.dart` replaced |
| T081 | Legacy PNG icon folders, `AppIcons`, `flutter_svg`, `tutorial_coach_mark`, unused widgets (`menu_group`, `type_switcher`, `bouncy_button`, `tutorial_card`) removed |
| T082 | Copy: "kamu", U+2212, em dash placeholders; recurring screens moved onto the kit (incl. delete from the form, `categoryIconKey`) |
| T083 | Indexes on `transactions(date, account_id, import_batch_id)` created on open. `performance_test.dart` (5 000 tx): Laporan was 442 ms → fixed to ~70–105 ms; Transaksi ~40–80 ms. **Not measured**: scrolling fps with glass (needs a device) |
| T084 | README / README_id feature lists, CODING_STYLE UI section |
| T085 | format clean, analyze 0, tests 132/132, `flutter build apk --debug` OK. **Not done**: walking quickstart on a device |

### Known gaps / follow-ups

- Google sign-in still uses the pre-existing placeholder `serverClientId` (`GANTI_DENGAN_WEB_CLIENT_ID_ANDA…`); Drive backup cannot work until a real OAuth client is configured.
- No run on a physical device or emulator in this session: glass blur performance, biometrics, Drive and file-picker flows are untested on hardware.

