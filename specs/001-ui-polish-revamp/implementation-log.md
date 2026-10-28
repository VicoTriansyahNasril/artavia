# Implementation Log — 001-ui-polish-revamp

## Session 2026-10-25
- HEAD at start: `168d878` (branch `main`). Pre-existing uncommitted changes (scutum/.gemini tooling, AGENTS.md, .gitignore) left untouched.
- Tasks targeted: T001–T061.
- Deviation: PIN hashing changed from SHA-256 to PBKDF2-HMAC-SHA256 600k via `cryptography` (security-standard.md); artifacts updated.

| Task | Files | Note |
| ---- | ----- | ---- |
| T001 | pubspec.yaml, pubspec.lock | +flutter_local_notifications, timezone, flutter_timezone, share_plus, file_picker, audioplayers, cryptography; assets/sounds/ registered |
| T002 | assets/sounds/success.wav | 220 ms two-tone chime, 9.7 KB, generator kept in scratchpad |
| T003 | android/app/build.gradle.kts, AndroidManifest.xml | desugaring + multidex; POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, scheduled receivers |
| T004 | test/*.dart | replaced smoke test with 5 real unit-test files (24 tests) |
| T005–T007 | colors.dart, main.dart, app_feedback.dart | slate tokens + categoryPalette; full theme; AppToast/AppDialog |
| T008–T013 | settings_service, period_service, finance_calc, date_format, database_helper (v11), transaction_store (new), data_refresh | balance effect now derived from stored row (fixes FR-018 at DB level) |
| T015–T027 | all screens/controllers | 0 `Colors.*`/hex outside colors.dart (grep verified) |
| T028–T034 | search, transaction_item, transaction_detail, transfer, add_transaction, profile, report, chart | FR-010…018 |
| T035–T042 | chart, report (→ Aset), home, budget, profile, account mgmt | FR-020…026 |
| T043–T057 | ledger deleted; settings controller/screen; notification, pin, sound, recurring, csv services; pin + recurring pages; home budget card; over-budget warning | FR-030…033 |
| T059 | — | `dart format` (54 files reformatted, incl. previously unformatted ones), `flutter analyze` 0 issues, `flutter test` 24/24 |
| T060 | README.md, README_id.md | feature list; corrected "no cloud sync" claim (Drive backup is optional) |

### Extra defects found & fixed during implementation (not in original audit)
- Edit transfer created a duplicate (TransferController ignored edit args) → FR-017.
- Deleting a transfer with admin fee left balances wrong → FR-018.
- Tapping an account in Laporan/Aset opened an empty *add* form (args ignored) → `AccountManagementController.openEditor`.
- Amount input filter `^-?[0-9.]*` would truncate at the comma once "1,000" format is chosen → allows `,`.
- Category delete copy claimed transactions are unaffected, but used categories cannot be deleted → copy fixed.
- `000` key on an empty amount produced "000"; adding a category from the grid reset the typed amount.

### Not verified here
- T061 manual device walk-through (notifications firing, PIN lifecycle, share sheet/file picker, sound) — needs a device/emulator.
