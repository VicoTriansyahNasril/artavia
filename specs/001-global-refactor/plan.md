# Implementation Plan: Global Refactoring & Optimization

**Feature Branch**: `001-global-refactor`  
**Created**: 2026-08-16  
**Status**: Approved (Bypassed by User)

## 1. Technical Context

- **Architecture Type**: Standalone Flutter Mobile App
- **Integration Target**: Local Device (No APIs)
- **Existing Design System**: Flutter Material/Cupertino standard (Custom constants from `commons/`)
- **State Management**: GetX
- **Key Dependencies**: GetX, flutter_lints

## 2. Constitution Check

- **Local-Only Mobile Architecture**: Validated. The refactor involves no API integrations.
- **AI Agent Standardization**: Validated. Using `AGENTS.md`.
- **Feature-Based Architecture**: Validated. Code will be restructured to match `lib/page/` structure if stray code exists.
- **UI Optimization and Clean Code**: Validated. Will implement `const` and granular `Obx`.

## 3. Implementation Phases

### Phase 1: Audit & Foundation (Fixing existing code)
- Run `flutter analyze` to list all current warnings.
- Resolve all null-safety warnings, unused imports, and dead code.
- Ensure strict separation: all UI widgets must be in `_screen.dart` and business logic in `_controller.dart`.

### Phase 2: Performance Optimization (Lag reduction)
- Audit all widgets for the missing `const` keyword.
- Refactor heavy `Obx` wrappers. Ensure `Obx` only wraps the specific text or widget that actually changes.
- Break down large build methods into smaller `StatelessWidget` classes.

### Phase 3: State & Memory Management (Fixing crashes and zombie pages)
- Audit GetX routing across the app.
- Replace incorrect uses of `Get.to()` with `Get.off()` or `Get.offAll()` where appropriate to prevent route stack buildup.
- Verify `onClose()` is called in controllers to release resources.
- Ensure lazy initialization (`Get.lazyPut()`) is used where possible.

### Phase 4: Stress Testing
- Manual/Automated rapid navigation tests to confirm zero OOM crashes.
- Monitor Flutter DevTools to ensure 60fps scrolling.

## 4. Technical Constraints

- Do not introduce any network layer or external API calls.
- Adhere strictly to dart null-safety guidelines.

## 5. Artifacts to Generate

- `data-model.md`: N/A (No new data models being introduced)
- `contracts/`: N/A (No external APIs)
