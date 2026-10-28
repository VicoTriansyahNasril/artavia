# Artavia - Money Tracker 💸

*Read this in other languages: [English](README.md) | [Bahasa Indonesia](README_id.md)*

> **🚧 Development Status: Active Development**  
> *This project is currently under active development. Features, UI, and database schemas are subject to change. Contributions and feedback are welcome!*

Artavia is a sleek, local-first, privacy-focused money tracker and expense manager mobile application built with Flutter. Designed with premium aesthetics and smooth micro-animations, it helps you manage your daily finances, track multiple accounts, and analyze your spending habits—all entirely offline.

## ✨ Key Features
- **Privacy First (Local)**: All data stays on the device (SQLite) with no tracking. Google Drive backup is optional and only runs when you ask for it.
- **Multiple Accounts & Transfers**: Wallets, bank accounts and e-money, including transfers with admin fees.
- **One Place for Analysis**: Summary, spending by category and weekly/monthly/yearly trends in the Grafik tab; net worth in the Aset tab.
- **Budgets**: Per-category limits with a summary on the history tab and an over-budget warning.
- **Recurring Transactions**: Salary, rent or subscriptions are recorded automatically.
- **Complete Settings**: Daily reminder, PIN lock, custom month start, number format, sound effect, and CSV export/import.
- **Calm UI**: Dark mode with a soft "slate" palette and measured contrast, easy on the eyes.

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
