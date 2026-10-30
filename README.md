# Artavia - Money Tracker 💸

*Read this in other languages: [English](README.md) | [Bahasa Indonesia](README_id.md)*

> **🚧 Development Status: Active Development**  
> *This project is currently under active development. Features, UI, and database schemas are subject to change. Contributions and feedback are welcome!*

Artavia is a sleek, local-first, privacy-focused money tracker and expense manager mobile application built with Flutter. Designed with premium aesthetics and smooth micro-animations, it helps you manage your daily finances, track multiple accounts, and analyze your spending habits—all entirely offline.

## ✨ Key Features
- **Privacy First (Local)**: All data stays on the device (SQLite). Optional Google Drive backups go to Artavia's hidden app folder and can be encrypted with a password (AES-256-GCM).
- **Fast entry ("Catat")**: One keypad screen for expense, income and transfer, with + − × ÷. Every category is shown in your own order; the keypad appears once you pick one, and the amount stays in view while you scroll. Date sits next to the amount, the note is typed inline beside the account, and the last account you used is preselected.
- **Readable amounts**: Rupiah fields group thousands as you type, following the 1.000 / 1,000 setting.
- **Transfers that remember fees**: The admin fee per account pair is preselected next time, paid from the source or deducted from what arrives, and booked as a "Biaya admin" expense.
- **Home, Reports, Accounts, Settings**: Period summary with a weekly insight, budget card and daily groups; week/month/year reports with trend bars and a category donut; grouped accounts with net worth and archiving.
- **Budgets, Search, Calendar**: "Needs attention" vs "Safe" with a safe daily amount, spelling suggestions in search, and a calendar with income/expense dots.
- **107 icons, 12 colours**: Categories use Lucide icons in 13 groups, with archiving and drag-to-reorder (the order Catat shows, or one tap to sort by usage). Accounts pick from a focused set of money and savings icons.
- **Undo & privacy**: Deleting can be undone for 5 seconds; one tap hides every amount.
- **Excel & CSV**: Export per sheet, 3-step import with duplicate detection and a 7-day undo.
- **"Kobalt" design**: Dark, light or system theme, glass surfaces, text size up to 150 %, PIN with fingerprint.

## 🛠️ Technology Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management & Routing**: [GetX](https://pub.dev/packages/get)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Backup**: [google_sign_in](https://pub.dev/packages/google_sign_in) + [Google Drive API](https://pub.dev/packages/googleapis) (`drive.appdata`, `drive.file`)
- **UI**: [Lucide icons](https://pub.dev/packages/lucide_icons_flutter), [fl_chart](https://pub.dev/packages/fl_chart), Plus Jakarta Sans
- **Architecture**: Feature-Based Architecture

## 📱 Platform
Android (`id.artavia.app`, minSdk 24), shared as an APK. The iOS project builds, but Google Drive backup is configured for Android only.

## 🚀 Getting Started

Since this is a Flutter project, make sure you have the Flutter SDK installed on your machine.

1. **Clone the repository**
   ```bash
   git clone https://github.com/VicoTriansyahNasril/artavia.git
   cd artavia
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app**
   ```bash
   flutter run
   ```

### Release APK
```bash
flutter build apk --release   # build/app/outputs/flutter-apk/app-release.apk
```
Release builds are signed with `android/upload-keystore.jks` via `android/key.properties`. Both are git-ignored, so keep a backup: updates must be signed with the same key. Without them the build falls back to the debug key.

### Google Drive backup
Sign-in only works for an app registered in Google Cloud with its package name and signing SHA-1. On a fork, create your own OAuth clients and put your Web client ID in `GoogleDriveService.webClientId` ([lib/core/services/google_drive_service.dart](lib/core/services/google_drive_service.dart)). Step-by-step guide: [docs/google-drive-android.md](docs/google-drive-android.md). Privacy policy: [vicotriansyahnasril.github.io/artavia/privacy.html](https://vicotriansyahnasril.github.io/artavia/privacy.html).

### App icon & splash
The launcher icons in `android/.../res/mipmap-*` and `ios/.../AppIcon.appiconset` come from the Artavia design pack. The splash follows the system light/dark theme; after changing `assets/brand/splash-icon.png` run:
```bash
dart run flutter_native_splash:create
```

## 📝 License
This project is open-source. Feel free to fork and modify!
