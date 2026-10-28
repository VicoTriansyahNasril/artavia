<!--
Sync Impact Report
- Version change: template → 1.0.0 (initial ratification)
- Principles defined:
  I. Local-First & Privacy
  II. Feature-Based GetX Architecture
  III. Single Source of Visual Truth
  IV. Consistent Data Mutations
  V. Honest, Simple UI
- Added sections: Technology Constraints, Quality Gates & Workflow, Governance
- Removed sections: none
- Templates: .scutum/templates/plan-template.md ✅ (gate is derived dynamically, no edit needed)
             .scutum/templates/spec-template.md ✅ (no mandatory section change)
             .scutum/templates/tasks-template.md ✅ (no new task category required)
- Deferred TODOs: none
-->

# Artavia Constitution

## Core Principles

### I. Local-First & Privacy

- All financial data MUST be stored locally in SQLite via `DatabaseHelper`.
- No analytics, tracking, or third-party API calls are permitted, except the
  user-initiated Google Drive backup/restore flow.
- Cloud features MUST be opt-in and the app MUST remain fully functional offline.

Rationale: privacy is the product's core promise (README "Privacy First").

### II. Feature-Based GetX Architecture

- Each feature lives in `lib/page/<feature>/` with `*_screen.dart` (UI only) and
  `*_controller.dart` (logic, DB access). Business logic MUST NOT live in screens.
- Navigation MUST use named routes registered in `lib/page/routes.dart`.
- Controllers MUST be provided via `Bindings` or `Get.put`/`lazyPut`.
- Imports MUST be absolute (`package:artavia/...`).

Rationale: matches CODING_STYLE.md and keeps features independently maintainable.

### III. Single Source of Visual Truth

- Every color used in UI MUST come from tokens in `lib/widgets/commons/colors.dart`
  (or a palette list defined there). Pages MUST NOT use `Colors.<material>` or
  raw `Color(0x...)` literals, except `Colors.transparent`.
- Feedback (snackbars/toasts) and confirmation dialogs MUST go through shared
  helpers so they look and behave identically everywhere.
- The palette MUST be calm and low-glare: no neon/fully-saturated hues on large
  areas; body text is off-white, not pure #FFFFFF.

Rationale: inconsistent, hardcoded, neon colors were the main UX complaint.

### IV. Consistent Data Mutations

- Any create/update/delete of transactions, accounts, categories, or budgets MUST
  go through `DatabaseHelper` methods that keep account balances consistent
  (DB transactions where more than one row changes).
- After any mutation, `refreshAllGlobalData()` MUST be called so every live view
  (home, charts, report, profile, budget, calendar, search) reflects the change.
- Aggregations shown in more than one place (e.g. net worth) MUST share one
  calculation rule.

Rationale: users must never see two different numbers for the same concept.

### V. Honest, Simple UI

- No dead UI: every visible button, menu, or toggle MUST perform its stated action.
  Unfinished features MUST be hidden or completed, never shipped as placeholders.
- Developer/debug tools MUST NOT be visible in release builds (`kDebugMode` guard).
- UI copy MUST be Bahasa Indonesia and consistent (month names, labels, tone).
- Prefer removing duplicated screens/flows over adding new ones (YAGNI).

Rationale: placeholders and duplicated views erode trust and add noise.

## Technology Constraints

- Flutter (Dart SDK ^3.1), GetX for state/routing, sqflite for storage,
  fl_chart for charts, intl with `id_ID` locale.
- New dependencies MUST be justified in the plan; prefer existing packages.
- Database schema changes MUST bump the DB version and add a non-destructive
  `onUpgrade` migration.

## Quality Gates & Workflow

- `flutter analyze` MUST report no issues before a change is considered done.
- Code MUST be formatted with `dart format`.
- Pure logic introduced or fixed (calculations, filters, aggregation) SHOULD be
  covered by unit tests under `test/`.
- Discovery-first: read and confirm understanding before changing code; keep
  changes in scope and state what is out of scope.
- Commits follow Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`).

## Governance

- This constitution supersedes ad-hoc practices; CODING_STYLE.md provides detailed
  runtime guidance and MUST stay consistent with it.
- Amendments require a documented change to this file with a version bump:
  MAJOR for removed/redefined principles, MINOR for new principles or sections,
  PATCH for wording fixes.
- Every plan MUST include a Constitution Check against Principles I–V; any
  violation MUST be justified in the plan's Complexity Tracking table.

**Version**: 1.0.0 | **Ratified**: 2026-10-25 | **Last Amended**: 2026-10-25
