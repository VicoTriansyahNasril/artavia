# Internal Service Contracts

Artavia has no network API. These are the Dart-level contracts new/changed services must satisfy.
Every mutation goes through `DatabaseHelper` / `TransactionStore` and calls
`refreshAllGlobalData()` afterwards (Principle IV). Access control: local single user; the
optional PIN gate (`LockOverlay`) protects all screens.

## ThemeService (new, `lib/core/services/theme_service.dart`)

```dart
class ThemeService extends GetxService {
  static ThemeService get to;
  Rx<ThemePref> pref;            // system | dark | light
  AppPalette get palette;        // resolved from pref + platform brightness
  RxBool reduceTransparency;
  Rx<TextScalePref> textScale;   // system | 0.9 | 1.0 | 1.15 | 1.3 | 1.5
  Future<void> setTheme(ThemePref p);        // persists, Get.changeThemeMode, forceAppUpdate
  Future<void> setReduceTransparency(bool v);
  Future<void> setTextScale(TextScalePref s);
}
```
Postcondition: after any setter, every visible screen re-renders with the new tokens.

## PrivacyService (new)

```dart
class PrivacyService extends GetxService {
  RxBool masked;                 // initial = settings.hide_on_open
  void toggle();
}
String formatRupiah(int value, {bool signed = false, bool maskable = true});
// masked → "Rp ••••••" (signed: "−Rp ••••••" / "+Rp ••••••"); uses U+2212 for minus.
```

## IconRegistry (new, `lib/widgets/commons/icon_registry.dart`)

```dart
class IconRegistry {
  static const List<IconGroup> groups;             // 13 groups, board order
  static IconEntry byKey(String? key);             // unknown → 'ellipsis'
  static List<IconEntry> search(String query);     // matches Indonesian label, case-insensitive
  static String legacyToKey({String? iconPath, int? iconCode});
}
```
Invariant: exactly 107 entries (71 base + 36 extra); keys unique.

## TransactionStore (extended)

```dart
Future<Map<String, dynamic>> deleteTransactionById(int id); // returns deleted row snapshot
Future<void> restoreTransaction(Map<String, dynamic> snapshot); // same id, re-applies balances
Future<int> duplicateToToday(int id);
Future<int> importBatch(String fileName, List<Map<String, dynamic>> rows); // returns batch id
Future<int> cancelImport(int batchId, {bool keepEdited = false}); // returns rows removed
```
`cancelImport` throws `ImportExpired` when the batch is > 7 days old.

## TransferFeeMemory (new, pure)

```dart
class TransferFeeMemory {
  Future<FeePref?> read(int fromId, int toId);
  Future<void> write(int fromId, int toId, FeePref pref);
  static List<int> quickChips(FeePref? last); // [last?, 2500, 6500] deduped, ascending after last
}
class TransferMath {                          // pure, unit-tested
  static TransferPreview preview({required int amount, required int fee,
      required FeeBearer bearer, required int sourceBalance});
  // Pengirim: source −(amount+fee), dest +amount
  // Penerima: source −amount, dest +(amount−fee); invalid if fee >= amount
  // shortfall = max(0, sourceDelta − sourceBalance)
}
```

## Calculator (pure, extended from add_transaction_controller)

```dart
class CalcEngine {
  void press(String key);   // digits, '000', '+', '−', '×', '÷', '⌫', 'C'
  String get expression;    // e.g. "45.000 + 12.500"
  int get result;           // left-to-right with ×/÷ precedence; ÷ rounds half-up
  bool get isValid;         // result > 0
}
```

## ImportService / ExportService (new, `lib/core/services/`)

```dart
Future<ExportResult> export({required ExportFormat format, required DateRange? range,
    required Set<ExportPart> parts});              // xlsx: one sheet per part; csv: transactions
Future<ParsedFile> parse(File f);                  // isolate; ≤20 MB, ≤50 000 rows
ColumnMapping guessMapping(ParsedFile f);          // header synonyms (Tgl, Tanggal, Date, Nominal, …)
ImportPreview preview(ParsedFile f, ColumnMapping m, Snapshot existing);
Future<int> commit(ImportPreview p, Resolutions r); // safety DB copy first, then one DB txn
```

## BackupService (replaces GoogleDriveService internals)

```dart
class BackupService extends GetxService {
  Rx<BackupState> state;   // disconnected | idle | running(progress) | failed(reason)
  Future<bool> connect();  // scope drive.appdata
  Future<void> disconnect();
  Future<void> backupNow({String? password});           // keeps newest 5
  Future<List<BackupEntry>> list();                     // from appProperties, no download
  Future<void> restore(BackupEntry e, {String? password}); // throws WrongPassword (uniform)
  Future<void> maybeAutoBackup();                       // on start/resume: enabled, >24h, Wi-Fi rule
}
```

## PinLockService (extended)

```dart
int get remainingAttempts;
Future<bool> canUseBiometrics();
Future<bool> unlockWithBiometrics();
```
