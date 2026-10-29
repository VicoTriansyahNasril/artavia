import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

/// Formats amounts with the user's thousands separator (Pengaturan → Format Angka).
class CurrencyService {
  CurrencyService._();
  static final CurrencyService to = CurrencyService._();

  /// `true` → 1,000 ; `false` → 1.000 (default). Set by SettingsService.
  bool useCommaSeparator = false;

  String get _locale => useCommaSeparator ? 'en_US' : 'id_ID';
  String get groupSeparator => useCommaSeparator ? ',' : '.';

  String format(num amount) {
    return NumberFormat.currency(
      locale: _locale,
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatWithoutSymbol(num amount) {
    return NumberFormat.currency(
      locale: _locale,
      symbol: '',
      decimalDigits: 0,
    ).format(amount).trim();
  }

  /// Privacy mode (FR-016). Set by PrivacyService; read by [money].
  bool masked = false;

  static const String minus = '−';
  static const String maskDots = '••••••';

  /// Display amount "Rp 45.000". With [signed] a "+" / "−" prefix is added
  /// (U+2212 minus). Returns "Rp ••••••" while privacy mode is on.
  String money(num amount, {bool signed = false, bool maskable = true}) {
    final sign =
        !signed ? (amount < 0 ? minus : '') : (amount < 0 ? minus : '+');
    if (maskable && masked) return '${sign}Rp $maskDots';
    return '${sign}Rp ${formatWithoutSymbol(amount.abs())}';
  }

  /// Digits only ("3.284.500"), masked in privacy mode.
  String digits(num amount, {bool maskable = true}) =>
      maskable && masked ? maskDots : formatWithoutSymbol(amount.abs());

  /// Short form for chart centers ("Rp 4,2 jt").
  String short(num amount, {bool maskable = true}) {
    if (maskable && masked) return 'Rp ••••';
    final a = amount.abs();
    String n(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
    if (a >= 1e9) return 'Rp ${n(a / 1e9)} M';
    if (a >= 1e6) return 'Rp ${n(a / 1e6)} jt';
    if (a >= 1e3) return 'Rp ${(a / 1e3).round()} rb';
    return 'Rp ${a.round()}';
  }

  String compact(num amount) {
    return NumberFormat.compactCurrency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    bool isNegative = newValue.text.startsWith('-');
    String numStr = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numStr.isEmpty) {
      return newValue.copyWith(text: isNegative ? '-' : '');
    }

    final int value = int.parse(numStr);
    final separator = CurrencyService.to.groupSeparator;
    final formatted = value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}$separator',
        );
    final result = isNegative ? '-$formatted' : formatted;

    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
