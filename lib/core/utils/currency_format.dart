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

/// Live thousands grouping for Rupiah inputs ("1250000" → "1.250.000"),
/// following the separator setting. Digits only; keeps the cursor next to
/// the same digit while regrouping.
class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  static final _nonDigit = RegExp(r'[^0-9]');

  /// "1.250.000" → 1250000 (0 when empty).
  static int parse(String text) =>
      int.tryParse(text.replaceAll(_nonDigit, '')) ?? 0;

  /// 1250000 → "1.250.000"; 0 → "" so the field shows its hint.
  static String initial(int value) =>
      value == 0 ? '' : CurrencyService.to.formatWithoutSymbol(value.abs());

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    final cursor = newValue.selection.end.clamp(0, text.length);
    var before = text.substring(0, cursor).replaceAll(_nonDigit, '');
    final after = text.substring(cursor).replaceAll(_nonDigit, '');

    // Backspace over a separator removes the digit before it instead.
    final deletedSeparator = text.length < oldValue.text.length &&
        before.length + after.length ==
            oldValue.text.replaceAll(_nonDigit, '').length;
    if (deletedSeparator && before.isNotEmpty) {
      before = before.substring(0, before.length - 1);
    }

    final digits = (before + after).replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > maxDigits) return oldValue;

    final separator = CurrencyService.to.groupSeparator;
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}$separator',
    );

    var offset = formatted.length;
    for (var seen = 0; offset > 0 && seen < after.length;) {
      offset--;
      if (formatted[offset] != separator) seen++;
    }
    if (offset > 0 && formatted[offset - 1] == separator) offset--;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
