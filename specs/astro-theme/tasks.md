# Implementation Tasks: Astro Bot Theme Redesign

## Story 1: Adopt PS5 / Astro Bot Color Palette
- [x] Task 1.1: Refactor `lib/widgets/commons/colors.dart`
  - Replace `colorBackground` with a clean Astro Bot white (e.g. `#F4F5F7` or absolute white) or deep space dark mode. (We will use the PS5 white/clean aesthetic with blue neon).
  - Replace `colorCard` with pure white (`#FFFFFF`) to pop against the slightly off-white background.
  - Update `colorAccent` to PS5 Cyan/Blue (`#00439C` or neon cyan).
  - Update semantic colors (expense/income) to highly vibrant, saturated shades.
- [x] Task 1.2: Update global texts and icons to match the new contrast requirements.

## Story 2: Apply Playful, Tactile UI Elements
- [x] Task 2.1: Create `lib/widgets/components/bouncy_button.dart`
  - Create a wrapper `StatefulWidget` or use `GestureDetector` with `AnimatedScale`.
  - Implement spring-based scaling (scales down to 0.95 on `onTapDown`, springs to 1.0 on `onTapUp`/`onTapCancel`).
- [x] Task 2.2: Apply `BouncyButton` to `HomeScreen`
  - Wrap primary actions (Transfer, Category, Budget, Report buttons) in `BouncyButton`.
- [x] Task 2.3: Apply `BouncyButton` to `TransferScreen` and `BudgetScreen`
  - Wrap the main submit/save buttons.

## Story 3: Implement Vibrant & Friendly Typography and Shapes
- [x] Task 3.1: Update Border Radiuses globally
  - Change standard `BorderRadius.circular(8)` or `16` to `BorderRadius.circular(20)` or `24` for a softer, toy-like feel in `TransferScreen`, `BudgetScreen`, etc.
- [x] Task 3.2: Verify no FPS drops (run `flutter analyze` to ensure `const` is maintained where possible).
