/// Keypad calculator for the Catat screen (FR-007/FR-008).
///
/// Pure Dart: keeps a token list of digit strings and operators
/// (`+ - * /`), evaluates × and ÷ before + and −, rounds ÷ half-up, and
/// ignores a trailing operator. Keys match `KeypadKey` in the Kobalt kit.
class CalcEngine {
  static const maxDigits = 12;
  static const _ops = {'+', '-', '*', '/'};

  final List<String> _tokens = [];

  CalcEngine([int initial = 0]) {
    setValue(initial);
  }

  /// Replaces everything with a single number (edit mode, segment switch).
  void setValue(int value) {
    _tokens.clear();
    if (value > 0) _tokens.add('$value');
  }

  void clear() => _tokens.clear();

  bool get isEmpty => _tokens.isEmpty;
  bool get hasOperator => _tokens.any(_ops.contains);
  bool get _lastIsOp => _tokens.isNotEmpty && _ops.contains(_tokens.last);

  /// Applies one key. Returns false when the key was rejected (too many
  /// digits), so the caller can warn.
  bool press(String key) {
    switch (key) {
      case 'C':
        clear();
      case 'back':
        if (_tokens.isEmpty) return true;
        final last = _tokens.removeLast();
        if (!_ops.contains(last) && last.length > 1) {
          _tokens.add(last.substring(0, last.length - 1));
        }
      case '+' || '-' || '*' || '/':
        if (_tokens.isEmpty) return true;
        if (_lastIsOp) _tokens.removeLast();
        _tokens.add(key);
      case '000':
        if (_tokens.isEmpty || _lastIsOp || _tokens.last == '0') return true;
        return _appendDigits('000');
      default:
        if (!RegExp(r'^\d$').hasMatch(key)) return true;
        return _appendDigits(key);
    }
    return true;
  }

  bool _appendDigits(String digits) {
    if (_tokens.isEmpty || _lastIsOp) {
      _tokens.add(digits == '0' ? '0' : digits);
      return true;
    }
    final current = _tokens.last;
    final next = current == '0' ? digits : current + digits;
    final normalized = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (normalized.length > maxDigits) return false;
    _tokens[_tokens.length - 1] = normalized;
    return true;
  }

  /// Value of the expression; a trailing operator is ignored and ÷ 0 gives 0.
  int get result {
    final t = List<String>.of(_tokens);
    if (t.isNotEmpty && _ops.contains(t.last)) t.removeLast();
    if (t.isEmpty) return 0;

    // First pass: × and ÷ (left to right).
    final terms = <int>[int.parse(t.first)];
    final addOps = <String>[];
    for (var i = 1; i < t.length; i += 2) {
      final op = t[i];
      final n = int.parse(t[i + 1]);
      if (op == '*') {
        terms[terms.length - 1] = terms.last * n;
      } else if (op == '/') {
        if (n == 0) return 0;
        terms[terms.length - 1] = _divideHalfUp(terms.last, n);
      } else {
        addOps.add(op);
        terms.add(n);
      }
    }
    // Second pass: + and −.
    var value = terms.first;
    for (var i = 0; i < addOps.length; i++) {
      value = addOps[i] == '+' ? value + terms[i + 1] : value - terms[i + 1];
    }
    return value;
  }

  static int _divideHalfUp(int a, int b) {
    final q = (a.abs() * 2 + b.abs()) ~/ (b.abs() * 2);
    return (a < 0) != (b < 0) ? -q : q;
  }

  bool get isValid => result > 0;

  /// "45.000 + 12.500" — empty for a single number (nothing to show above
  /// the big amount).
  String expression({String groupSeparator = '.'}) {
    if (!hasOperator) return '';
    return _tokens.map((tok) {
      return switch (tok) {
        '+' => '+',
        '-' => '−',
        '*' => '×',
        '/' => '÷',
        _ => group(int.parse(tok), groupSeparator),
      };
    }).join(' ');
  }

  /// 3284500 → "3.284.500".
  static String group(int value, [String separator = '.']) {
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(separator);
      buf.write(digits[i]);
    }
    return '${value < 0 ? '−' : ''}$buf';
  }
}
