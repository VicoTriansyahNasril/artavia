# AGENTS.md

Project context for AI agents (Antigravity, Cursor, etc). Please read this file carefully as it outlines the core architecture and coding guidelines for the Artavia project.

## Overview
Artavia is a mobile application built with Flutter.
**CRITICAL**: This is a **Local-Only Mobile Architecture**. We do NOT use any external APIs or backend services. All data, logic, and state are handled locally on the device (e.g., using sqflite or local storage). Do not attempt to write network requests, API clients, or REST calls.

## Architecture
- **Framework**: Flutter
- **State Management & Routing**: GetX
- **Pattern**: Feature-Based Architecture
- **Directory Structure**:
  - `lib/page/`: Contains feature folders (e.g., `lib/page/home/`).
  - `lib/widgets/`: Reusable UI components.
  - `lib/page/routes.dart`: Centralized GetPage routing.

Each feature folder must strictly separate concerns:
- `_screen.dart`: For UI only (StatelessWidget/GetView).
- `_controller.dart`: For business logic, state (`.obs`), and local data manipulation. 

## Conventions
- **Naming**:
  - `PascalCase` for Classes, Enums, Typedefs.
  - `snake_case` for files/folders (`home_screen.dart`).
  - `camelCase` for variables, functions.
  - `SCREAMING_SNAKE_CASE` for global configuration constants.
- **UI Guidelines**:
  - `const` constructors are strictly mandatory for all static widgets to maximize FPS.
  - Granular reactivity: wrap only the smallest possible widget tree in `Obx`.
  - Do not use functions that return `Widget`. If a widget gets complex, extract it into its own `StatelessWidget` class.
- **Null Safety**:
  - Avoid the bang operator (`!`). Use `??` or early returns to handle potential nulls safely.

## Build, run, test
- `flutter run` to run the application locally.
- `flutter analyze` to check for linter warnings.
- `dart format lib/` to format code.

## How agents should work here
- **Local Only**: Remember, no APIs. If data is needed, mock it or use local storage.
- Discovery-first: read and confirm understanding before changing code.
- Keep changes in scope; state what is OUT OF SCOPE; verify end-to-end.
- Prefer the smallest viable change; follow the `CODING_STYLE.md` exactly.
