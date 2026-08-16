# Task List: Global Refactoring & Optimization

**Feature Branch**: `001-global-refactor`
**Status**: Ready for execution

## Phase 1: Audit & Foundation
- [ ] Task 1.1: Run `flutter analyze` and fix all basic linter warnings (unused imports, dead code).
- [ ] Task 1.2: Enforce null-safety constraints (replace unsafe `!` operators with `??` or early returns).
- [ ] Task 1.3: Audit folder structure to ensure strict adherence to `lib/page/<feature>/` architecture.

## Phase 2: UI Optimization
- [x] Task 2.1: Enforce `const` Constructors
- [x] Task 2.2: Fix Granular State Updates (Obx Scope)
  - Extracted heavy non-const widgets in `home_screen.dart` into `HistoryView` class.
  - Moved heavy data grouping logic to `HomeController` instead of executing it inside `build`.
- [ ] Task 2.3: Extract complex inline widgets (functions returning `Widget`) into proper `StatelessWidget` classes.

## Phase 3: Routing & Memory Management
- [x] Task 3.1: Audit Navigation Calls
- [x] Task 3.2: Manage Controller Lifecycle
  - Removed explicit `Get.put()` calls inside `BudgetScreen` and `TransferScreen`.
  - Created `BudgetBinding` and `TransferBinding`.
  - Updated `routes.dart` to use GetX Bindings, allowing automatic cleanup.
- [ ] Task 3.3: Implement `Get.lazyPut()` in bindings for efficient controller initialization.

## Phase 4: Stress Testing & Verification
- [ ] Task 4.1: Manually stress-test rapid navigation to verify pages are correctly popped and memory is freed.
- [ ] Task 4.2: Verify frame rendering times using Flutter DevTools.
