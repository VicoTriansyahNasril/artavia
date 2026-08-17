import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CurrencyService {
  CurrencyService._();
  static final CurrencyService to = CurrencyService._();

  String format(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatWithoutSymbol(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    ).format(amount);
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
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    final result = isNegative ? '-$formatted' : formatted;

    return newValue.copyWith(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
