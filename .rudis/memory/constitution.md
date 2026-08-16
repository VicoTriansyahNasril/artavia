<!--
This is the canonical constitution scaffold shipped by Rudis. It is copied to
.rudis/memory/constitution.md on `rudis init` and read by `/rudis.constitution`
as the required structure when drafting or amending a project's constitution.
Edit this file to change the scaffold for all future/updated projects — do not
hand-maintain a second copy elsewhere; that duplication is exactly what let the
template and a live constitution drift apart before.
-->

<!--
SYNC IMPACT REPORT
Version: 1.0.0 (Initial Creation)
Principles Added: Local-Only Architecture, AI Agent Standardization, Feature-Based Architecture, UI Optimization
Templates Pending: N/A
-->

# Artavia Mobile Sifa Constitution

## Core Principles

### I. Local-Only Mobile Architecture
No external APIs are used. All data processing, storage (e.g., local database like sqflite), and business logic must reside entirely within the mobile application. The application must be fully functional offline at all times.

### II. AI Agent Standardization
All AI context and guidelines must be documented in `AGENTS.md`. We do not use agent-specific files like `CLAUDE.md`. Agents must strictly follow the `CODING_STYLE.md` and this constitution.

### III. Feature-Based Architecture
Strict separation of concerns using GetX. The `lib/page/` directory contains feature folders. UI logic goes in `_screen.dart` and business logic goes in `_controller.dart`. Mixing business logic in UI files is strictly prohibited.

### IV. UI Optimization and Clean Code
Constant (`const`) constructors are mandatory for static widgets to ensure high FPS. State updates must be granular using `.obs` and `Obx` only around the smallest widget necessary. Methods should not return widgets; complex widgets must be extracted into their own `StatelessWidget` classes.

## Development Workflow

Code must pass `flutter analyze` and `dart format` before any commit. 
Commits must follow Conventional Commits (feat, fix, refactor, chore, docs).
Null Safety is strictly enforced. The use of the bang operator (`!`) is forbidden unless absolutely mathematically guaranteed to be non-null; prefer `??` or early returns.

## Governance

This Constitution supersedes all other practices. All AI agents must adhere to the rules set within this document and the associated `AGENTS.md`.

**Version**: 1.0.0 | **Ratified**: 2026-08-16 | **Last Amended**: 2026-08-16
