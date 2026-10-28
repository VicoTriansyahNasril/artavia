# Tasks: UI Polish & Feature Completion Revamp

**Input**: Design documents from `specs/001-ui-polish-revamp/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Unit tests for pure logic are included (constitution Quality Gates: "pure logic SHOULD be covered by unit tests").

## Format: `[ID] [P?] [Story] [FR-###?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- Paths are relative to repo root `D:\Project\Artavia`.

---

## Phase 1: Setup

- [X] T001 Add dependencies flutter_local_notifications, timezone, flutter_timezone, share_plus, file_picker, audioplayers, cryptography via `flutter pub add` and register `assets/sounds/` in pubspec.yaml
- [X] T002 [P] Generate 180 ms two-tone chime `assets/sounds/success.wav` (22 kHz mono, <20 KB) with a script kept in scratchpad (not committed)
- [X] T003 [P] Enable core library desugaring in android/app/build.gradle.kts and add notification receivers + `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` to android/app/src/main/AndroidManifest.xml
- [X] T004 [P] Create `test/` directory with a smoke test file test/smoke_test.dart so `flutter test` runs

---

## Phase 2: Foundational (blocks all stories)

- [X] T005 [FR-001][FR-003] Rewrite token values in lib/widgets/commons/colors.dart: slate palette, add `colorText`, `colorWarning`, `categoryPalette` (12), remove deprecated tokens
- [X] T006 [FR-001][FR-006] Rebuild theme in lib/main.dart from tokens (colorScheme, dialog, datePicker, timePicker, snackbar, progress, switch, input, bottom sheet, chip) and set system UI colors
- [X] T007 [P] [FR-004][FR-005] Create lib/widgets/components/app_feedback.dart with `AppToast.success/warning/error/info` and `AppDialog.confirm` (destructive button uses dark text per R1)
- [X] T008 [P] Create lib/core/services/settings_service.dart (GetxService, loads keys from contracts/settings-keys.md, typed getters/setters, `reload()` after reset)
- [X] T009 [FR-021][FR-031c] Create lib/core/services/period_service.dart (`activeMonth`, `startDay` from SettingsService, `rangeFor`, `periodOf(date)`, Indonesian label, prev/next) and register services in lib/main.dart
- [X] T010 [P] [FR-022] Add Indonesian month/day helpers (`monthShortId`, `monthLongId`, `dayShortId`) in lib/core/utils/date_format.dart
- [X] T011 [P] [FR-013][FR-014] Create lib/core/utils/finance_calc.dart: `computeNetWorth`, `buildTrend(mode,…)`, `filterByType` (search), `summarizeBudget`
- [X] T012 [FR-031b] DB v11 in lib/core/database/database_helper.dart: `recurring_rules` create + upgrade, `readTransactionsByRange`, recurring CRUD, `replaceTransaction`, `replaceTransfer`, `insertRecurringOccurrences`, `readBudgetsByMonth` unchanged
- [X] T013 [FR-015] Extend lib/core/utils/data_refresh.dart to refresh ProfileController and SearchController (and remove report expense refresh dependency later)
- [X] T014 [P] Unit tests test/finance_calc_test.dart and test/period_service_test.dart (net worth with excluded/negative, trend buckets week/month/year, period ranges for start day 1 and 25, Dec→Jan wrap)

**Checkpoint**: tokens/theme/helpers/services ready.

---

## Phase 3: User Story 1 — Tampilan kalem dan konsisten (P1) 🎯 MVP

**Goal**: one calm palette everywhere; uniform toasts/dialogs.
**Independent Test**: open every screen/dialog; color grep in quickstart returns nothing outside colors.dart.

### Bolt 1 — tabs & shared widgets
- [X] T015 [P] [US1][FR-002] Apply tokens in lib/page/home/home_screen.dart (FAB without glow, nav, summary, date headers)
- [X] T016 [P] [US1][FR-002] Apply tokens in lib/page/chart/chart_screen.dart and lib/page/chart/chart_controller.dart (fallback colors → categoryPalette, "Lain-lain" → colorGrey)
- [X] T017 [P] [US1][FR-002] Apply tokens in lib/page/report/report_screen.dart and lib/page/report/report_controller.dart
- [X] T018 [P] [US1][FR-002] Neutral header + tokens in lib/page/profile/profile_screen.dart; toasts/dialogs in lib/page/profile/profile_controller.dart
- [X] T019 [P] [US1][FR-002][FR-004][FR-005] Tokens + AppToast/AppDialog in lib/widgets/transaction/transaction_item.dart and lib/widgets/components/tutorial_card.dart, lib/widgets/components/bouncy_button.dart (if needed)

### Bolt 2 — secondary screens
- [X] T020 [P] [US1][FR-002][FR-004][FR-005][FR-006] Tokens + helpers in lib/page/add_transaction/add_transaction_screen.dart and add_transaction_controller.dart (remove custom yellow date picker theme)
- [X] T021 [P] [US1][FR-002][FR-004][FR-006] Tokens + helpers in lib/page/transfer/transfer_screen.dart and transfer_controller.dart (Colors.blue → accent)
- [X] T022 [P] [US1][FR-002][FR-003][FR-004][FR-005] Tokens + helpers in lib/page/account_management/* (presetColors → categoryPalette, default type colors from palette)
- [X] T023 [P] [US1][FR-002][FR-003][FR-004][FR-005] Tokens + helpers in lib/page/category_management/* (palette → categoryPalette, no black)
- [X] T024 [P] [US1][FR-002][FR-004][FR-005] Tokens + helpers in lib/page/budget/* (dialogs: no #1E1E1E/#FFCA28)
- [X] T025 [P] [US1][FR-002] Tokens in lib/page/calendar/calendar_screen.dart, lib/page/search/search_screen.dart, lib/page/transaction_detail/transaction_detail_screen.dart (hero gradient toned down; transfer = accent)
- [X] T026 [US1][FR-003] Update default category seed colors in lib/core/database/database_helper.dart / lib/core/database/dummy_data.dart to categoryPalette (fresh installs only)
- [X] T027 [US1][FR-002] Run color grep (quickstart) and fix remaining hits

**Checkpoint**: US1 verifiable on its own.

---

## Phase 4: User Story 2 — Data selalu benar dan sinkron (P1)

**Goal**: A1–A6 + FR-016–018 fixed.
**Independent Test**: quickstart steps 2–3, 6–8.

- [X] T028 [P] [US2][FR-010] Search: real type filter via `filterByType` (incl. Transfer) and map `categoryIconPath`, adminFee fields in lib/page/search/search_controller.dart
- [X] T029 [US2][FR-011][FR-018] TransactionItem/Detail: pass admin_fee, admin_fee_type, destination ids in args; detail Edit routes transfer → `/transfer`; delete passes fee — lib/widgets/transaction/transaction_item.dart, lib/page/transaction_detail/transaction_detail_screen.dart; map adminFee in lib/page/home/home_controller.dart, lib/page/calendar/calendar_controller.dart
- [X] T030 [US2][FR-017] Transfer edit mode in lib/page/transfer/transfer_controller.dart using `replaceTransfer` (prefill source/dest/amount+fee/date/note; title "Edit Transfer" in lib/page/transfer/transfer_screen.dart)
- [X] T031 [US2][FR-012][FR-016] Add transaction: no-account empty state with "Buat Rekening" in lib/page/add_transaction/add_transaction_screen.dart; guard in controller; edit uses `replaceTransaction` (always removes old row)
- [X] T032 [US2][FR-013] Use `computeNetWorth` in lib/page/profile/profile_controller.dart and lib/page/report/report_controller.dart
- [X] T033 [US2][FR-014] Chart: range queries, Pekan navigation, Tahun 12 buckets, x-axis labels via `buildTrend` in lib/page/chart/chart_controller.dart and chart_screen.dart
- [X] T034 [US2][FR-015] Settings reset → `refreshAllGlobalData()` + SettingsService reload (moved into SettingsController in T046); Search/Profile refresh verified

**Checkpoint**: US2 verifiable.

---

## Phase 5: User Story 3 — Navigasi lebih sederhana (P2)

**Goal**: one analysis place, shared month, Indonesian copy, debug-only dev menu.
**Independent Test**: quickstart steps 4–5, 11.

- [X] T035 [US3][FR-020] Grafik: add summary card (Pengeluaran/Pemasukan/Saldo) in lib/page/chart/chart_screen.dart
- [X] T036 [US3][FR-020] Aset: remove TabBar/Analisis + expenseByCategory from lib/page/report/report_screen.dart and report_controller.dart; bottom nav label "Aset" in lib/page/home/home_screen.dart
- [X] T037 [US3][FR-021] Home, Chart (Bulan), Budget follow PeriodService (`ever(activeMonth)`; navigation updates shared month) in lib/page/home/home_controller.dart, lib/page/chart/chart_controller.dart, lib/page/budget/budget_controller.dart
- [X] T038 [US3][FR-022] Indonesian month picker & labels in lib/page/home/home_screen.dart and controllers (remove local month arrays)
- [X] T039 [US3][FR-023] Wrap dev menu with `kDebugMode` in lib/page/profile/profile_screen.dart
- [X] T040 [US3][FR-024] Category sheet: Indonesian dates + tap → detail in lib/page/chart/chart_screen.dart
- [X] T041 [US3][FR-025] Accurate delete-account copy (incl. recurring rules note) in lib/page/account_management/account_management_controller.dart
- [X] T042 [US3][FR-026] Remove `isFabOpen`, `prevMonth/nextMonth`, `calculatedNetWorth`, unused code in lib/page/home/home_controller.dart, lib/page/report/report_controller.dart

---

## Phase 6: User Story 4 — Tidak ada fitur palsu (P2)

**Goal**: Buku Kas removed; every Settings item real; budget surfaced.
**Independent Test**: quickstart steps 9–10.

### Bolt 1 — removal & settings shell
- [X] T043 [US4][FR-030] Delete lib/page/ledger/, remove route in lib/page/routes.dart, Home leading icon, Profile item
- [X] T044 [US4][FR-031] Create lib/page/settings/settings_controller.dart + settings_binding.dart; rewrite lib/page/settings/settings_screen.dart as GetView with all items; register binding in routes
- [X] T045 [US4][FR-032] "Cadangkan Data" → back to root + Saya tab, in settings_controller.dart

### Bolt 2 — prefs features
- [X] T046 [US4][FR-031g] Number format: CurrencyService/CurrencyInputFormatter read separator from SettingsService in lib/core/utils/currency_format.dart; picker in settings
- [X] T047 [US4][FR-031c] Month start day picker (1–28) in settings; PeriodService recompute + refresh
- [X] T048 [P] [US4][FR-031h] lib/core/services/sound_service.dart; play after save in add_transaction_controller.dart and transfer_controller.dart
- [X] T049 [P] [US4][FR-031a] lib/core/services/notification_service.dart (init tz, permission, schedule daily, cancel); toggle + time picker in settings; reschedule at startup in lib/main.dart

### Bolt 3 — PIN
- [X] T050 [US4][FR-031d] lib/core/services/pin_lock_service.dart (salt + PBKDF2-SHA256 600k in isolate, verify, lifecycle lock with 10 s grace, attempts/cooldown)
- [X] T051 [US4][FR-031d] lib/page/pin/pin_screen.dart, pin_controller.dart, pin_binding.dart (modes setup/unlock/disable), route `/pin`; startup gate in lib/main.dart

### Bolt 4 — recurring
- [X] T052 [US4][FR-031b] lib/core/models/recurring_rule.dart + lib/core/services/recurring_service.dart (`dueDates`, `runDue` at startup → refresh)
- [X] T053 [US4][FR-031b] lib/page/recurring/ list + form screens, controller, binding; route `/recurring`

### Bolt 5 — CSV
- [X] T054 [US4][FR-031e][FR-031f] lib/core/services/csv_service.dart (writer, parser, validation, export+share, pick+preview+import) + DB `importTransactions` in database_helper.dart
- [X] T055 [US4][FR-031e][FR-031f] Export/Import items + preview dialog in settings

### Bolt 6 — budget
- [X] T056 [US4][FR-033] Home budget summary card (tap → /budget) in lib/page/home/home_controller.dart and home_screen.dart
- [X] T057 [US4][FR-033] Over-budget warning after expense save in lib/page/add_transaction/add_transaction_controller.dart

### Tests
- [X] T058 [P] [US4] Unit tests test/recurring_test.dart (daily/weekly/monthly, clamp 31→28/29, last_run, cap), test/csv_test.dart (quoting, BOM, round-trip, validation), test/pin_hash_test.dart, test/currency_format_test.dart

---

## Phase 7: Polish & Cross-Cutting

- [X] T059 `dart format lib test`; `flutter analyze` = 0 issues; `flutter test` green
- [X] T060 [P] Update README.md / README_id.md feature list (no "Buku Kas"; settings features; palette note)
- [ ] T061 Walk quickstart.md checklist; record any manual steps not executable here

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 → (US1 ∥ US2) → US3 → US4 → Polish.
- US2 T029–T031 touch files also restyled in US1 → run US1 first in practice (same files).
- US3 T037 depends on T009; US4 T047 depends on T009/T037; T049/T050/T052 depend on T008.
- T034 completed inside T044.

## Parallel Example

```text
Phase 2: T007, T008, T010, T011 in parallel; then T009, T012.
US1 Bolt 1: T015–T019 in parallel (different files).
US4: T048 ∥ T049 after T044.
```

## Implementation Strategy

MVP = Phase 1–3 (calm palette everywhere). Then US2 (correctness), US3 (simplify), US4 in bolts. Each checkpoint: `flutter analyze` clean.

## FR Coverage

FR-001 T005,T006 · FR-002 T015–T025,T027 · FR-003 T005,T022,T023,T026 · FR-004 T007,T019–T024 · FR-005 T007,T019,T020,T022–T024 · FR-006 T006,T020,T021 · FR-010 T028 · FR-011 T029 · FR-012 T031 · FR-013 T011,T032 · FR-014 T011,T033 · FR-015 T013,T034 · FR-016 T031 · FR-017 T030 · FR-018 T029 · FR-020 T035,T036 · FR-021 T009,T037 · FR-022 T010,T038 · FR-023 T039 · FR-024 T040 · FR-025 T041 · FR-026 T042 · FR-030 T043 · FR-031 T044 · FR-031a T049 · FR-031b T012,T052,T053 · FR-031c T009,T047 · FR-031d T050,T051 · FR-031e/f T054,T055 · FR-031g T046 · FR-031h T048 · FR-032 T045 · FR-033 T056,T057
