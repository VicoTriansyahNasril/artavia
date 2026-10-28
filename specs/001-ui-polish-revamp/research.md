# Research: UI Polish & Feature Completion Revamp

All Technical Context unknowns resolved. Versions verified with `flutter pub add <pkg> --dry-run`
on Flutter 3.44.8 / Dart 3.12.2 (2026-10-25).

## R1 — Palette
- **Decision**: calm "slate" dark palette (plan.md table), single soft-blue accent #7AA2F7, muted semantic green/red/amber, 12-hue category palette at equal saturation.
- **Rationale**: measured WCAG contrast — text 14.2:1 on card, secondary 5.7:1, all semantic colors ≥5.4:1 even on `colorSurface` (NFR-001). Neon colors removed; pure white replaced by off-white #E7E9EE to cut glare.
- **Finding**: white text on `colorExpense` = 2.9:1 → filled destructive buttons use dark `colorOnAccent` text (6.5:1).
- **Alternatives**: keep cyan accent desaturated (#4FB3BF) — rejected, still clashes with income green; teal accent — too close to income.

## R2 — Enforcing tokens
- **Decision**: replace `Colors.white/grey/...` and raw hex in `lib/page/**` and `lib/widgets/**` with tokens; add `colorText` (off-white) and rename text uses of `colorWhite`. Remove deprecated tokens (`colorRed`, `colorBorder`, `colorDisabledFill`, `colorInfo`, `colorBlack` — 0 uses).
- **Verification**: `grep -rnE "Colors\.(?!transparent)|Color\(0x" lib --include=*.dart` must only hit `colors.dart` (SC-001). Data-driven colors (`Color(item['color'] as int)`) are allowed.

## R3 — Feedback helpers
- **Decision**: `AppToast.success/warning/error/info(title, msg)` wrapping `Get.snackbar` (bottom, margin 16, radius 12, 2 s, `colorSurface` background + colored leading icon, `colorText` text) and dedupe via `Get.isSnackbarOpen` for warnings; `AppDialog.confirm({title, message, confirmLabel, destructive, onConfirm})` returning `Future<bool>` built on `Get.dialog(AlertDialog)` using theme.
- **Rationale**: tinted surface + colored icon is calmer than fully colored snackbars; one place to change.

## R4 — Shared period & custom month start
- **Decision**: `PeriodService` (GetxService) holds `activeMonth` (Rx<DateTime> year/month) and reads `startDay` from SettingsService. `rangeFor(y,m)`: if startDay==1 → [y-m-1, next month 1); else → [(m-1)-startDay, m-startDay). Label is month *m* (the month in which the period ends), e.g. start 25: "Okt" = 25 Sep–24 Okt. Default active month = period containing today.
- Home, Chart(Bulan), Budget `ever(activeMonth)` and reload. Budget keys stay (year, month) = label month.
- `DatabaseHelper.readTransactionsByRange(start, end)` replaces month query for these screens; Calendar keeps calendar months.
- **Alternatives**: per-controller month (current) — rejected (FR-021).

## R5 — Net worth rule
- **Decision**: `computeNetWorth(accounts)` in `finance_calc.dart`: skip `is_excluded==1`; asset = sum of positive balances, liability = sum of |negative balances|, net = asset − liability. Used by Profile and Aset. Unit tested.

## R6 — Trend aggregation
- **Decision**: `buildTrend(transactions, mode, rangeStart)` returns buckets: Pekan → 7 day buckets from rangeStart (Mon-based week containing anchor, navigable ±7 days), x labels Sen..Min; Bulan → day-of-period buckets; Tahun → 12 month buckets (x = 1..12). Year/week queries use the range query instead of `readAllTransactions()` + filter (performance).

## R7 — Daily reminder
- **Decision**: flutter_local_notifications 22.x + timezone + flutter_timezone; `zonedSchedule(..., matchDateTimeComponents: DateTimeComponents.time, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle)` — inexact avoids `SCHEDULE_EXACT_ALARM` permission (Play policy). Request `POST_NOTIFICATIONS` (Android 13+) / iOS alert permission when the toggle turns on; if denied, toggle reverts with a warning toast.
- Android setup: `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`; manifest `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` (+ `RECEIVE_BOOT_COMPLETED`). Exact API signatures confirmed from package source at implement time.
- Re-schedule on app start if enabled (idempotent, fixed notification id 1001). Cancel on disable and on Reset.

## R8 — Recurring transactions
- **Decision**: table `recurring_rules`; `dueDates(rule, today)` pure: start from `last_run_date` next occurrence (or `start_date`), step daily/weekly(+7)/monthly (same day-of-month, clamped to month end, anchored on start_date's day), up to and including today; cap 400 occurrences per run (safety). `runDue()` at startup after DB open: for each active rule, in one DB transaction insert each occurrence (balance-aware, note suffixed nothing, date = occurrence at 08:00) and set `last_run_date` — guarantees exactly-once.
- Scope: pengeluaran/pemasukan only (transfers excluded — documented in UI).
- Rules referencing a deleted category/account: account/category deletion is only blocked by existing *transactions*, so `recurring_rules` FKs use `ON DELETE CASCADE` — deleting an account/category also removes its rules (delete-dialog copy mentions it).

## R9 — PIN lock
- **Decision**: 4-digit PIN; store `pin_salt` (16 random bytes from `Random.secure`, base64) and `pin_hash` = PBKDF2-HMAC-SHA256 (600,000 iterations, 256-bit) via the `cryptography` package, computed off the UI thread (`compute`). Plain SHA-256 rejected per `.scutum/templates/security-standard.md` (passwords: PBKDF2 ≥ 600k / bcrypt ≥ 12 / Argon2id; no roll-your-own). `PinLockService` (GetxService + WidgetsBindingObserver): if enabled, lock at startup (initial route `/pin` with `next` = home) and on `resumed` after `paused` longer than **10 s grace** (avoids locking after share sheet / file picker / Google sign-in). PIN screen uses `PopScope(canPop:false)` in unlock mode. After 5 wrong attempts → 30 s cooldown. Disable requires PIN. Forgot PIN → explained: only "Reset Seluruh Data" (which deletes settings, so lock is removed).
- **Alternatives**: local_auth biometrics — not requested, adds platform setup.

## R10 — CSV
- **Decision**: own RFC-4180 writer/parser (quotes, commas, newlines in note) — no `csv` package needed. Format in contracts/csv-format.md. Export → temp dir (`path_provider`) `artavia-YYYYMMDD-HHmm.csv` with UTF-8 BOM (Excel) → `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`. Import → `FilePicker` (custom ext csv) → parse → preview dialog (valid/invalid counts + first errors) → single DB transaction: create missing categories (palette color, default icon) / accounts (type "Lainnya", balance 0), insert rows with balance updates (transfers via transfer logic incl. admin fee).

## R11 — Number format
- **Decision**: setting `number_format` = `dot` (1.000, default) | `comma` (1,000). `CurrencyService` uses `NumberFormat` locale `id_ID` vs `en_US` (0 decimals); `CurrencyInputFormatter` uses the same separator. Parsing everywhere already strips non-digits → unaffected. Changing triggers `Get.forceAppUpdate()` / refresh.

## R12 — Sound
- **Decision**: audioplayers `AudioPlayer` (low-latency mode) playing `assets/sounds/success.wav` (generated 180 ms two-tone sine, 22 kHz mono, < 20 KB). Played after successful add/transfer save when `sound_effect`=true. Failures are swallowed (never block saving).

## R13 — Transfer edit & delete with fee (FR-017/018)
- **Decision**: pass `admin_fee`, `admin_fee_type`, destination account in edit/detail args (TransactionModel already has fields; mappers must populate them). `TransferController` reads `isEdit` args → prefills source/dest/amounts (source = amount + fee), date, note; on save deletes old transfer (balance-aware, with fee) then inserts new — in **one DB transaction** via new `DatabaseHelper.replaceTransfer`. Delete paths pass fee.
- Same pattern for income/expense edit: new `DatabaseHelper.replaceTransaction(oldId, oldAccountId?, oldAmount, oldType, newRow, newAccountId, change)` in one transaction; old row always deleted even when old account missing (FR-016).

## R14 — Simplification details
- Grafik gets summary card; Report's `expenseByCategory` + Analisis tab removed; bottom nav label "Aset" (icon `account_balance_wallet`).
- Buku Kas: delete `lib/page/ledger/`, route, Home leading icon, Profile item.
- Dev menu wrapped in `if (kDebugMode)`.
- Unused: `HomeController.isFabOpen`, `prevMonth/nextMonth` (replaced by PeriodService), `ReportController.calculatedNetWorth`.
