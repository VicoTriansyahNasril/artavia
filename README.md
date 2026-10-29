# Artavia - Money Tracker 💸

*Read this in other languages: [English](README.md) | [Bahasa Indonesia](README_id.md)*

> **🚧 Development Status: Active Development**  
> *This project is currently under active development. Features, UI, and database schemas are subject to change. Contributions and feedback are welcome!*

Artavia is a sleek, local-first, privacy-focused money tracker and expense manager mobile application built with Flutter. Designed with premium aesthetics and smooth micro-animations, it helps you manage your daily finances, track multiple accounts, and analyze your spending habits—all entirely offline.

## ✨ Key Features
- **Privacy First (Local)**: All data stays on the device (SQLite). Optional Google Drive backups go to Artavia's hidden app folder and can be encrypted with a password (AES-256-GCM).
- **Fast entry ("Catat")**: One keypad screen for expense, income and transfer, with + − × ÷, your 10 most-used categories and the last account you used.
- **Transfers that remember fees**: The admin fee per account pair is preselected next time, paid from the source or deducted from what arrives, and booked as a "Biaya admin" expense.
- **Home, Reports, Accounts, Settings**: Period summary with a weekly insight, budget card and daily groups; week/month/year reports with trend bars and a category donut; grouped accounts with net worth and archiving.
- **Budgets, Search, Calendar**: "Needs attention" vs "Safe" with a safe daily amount, spelling suggestions in search, and a calendar with income/expense dots.
- **107 icons, 12 colours**: Categories use Lucide icons in 13 groups with drag-to-reorder and archiving.
- **Undo & privacy**: Deleting can be undone for 5 seconds; one tap hides every amount.
- **Excel & CSV**: Export per sheet, 3-step import with duplicate detection and a 7-day undo.
- **"Kobalt" design**: Dark, light or system theme, glass surfaces, text size up to 150 %, PIN with fingerprint.

## 🛠️ Technology Stack
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management & Routing**: [GetX](https://pub.dev/packages/get)
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite)
- **Architecture**: Feature-Based Architecture

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

## 📝 License
This project is open-source. Feel free to fork and modify!
