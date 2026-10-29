import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/haptics_service.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Key values emitted by [Keypad.onKey].
abstract final class KeypadKey {
  static const clear = 'C';
  static const backspace = 'back';
  static const thousand = '000';
  static const divide = '/';
  static const multiply = '*';
  static const minus = '-';
  static const plus = '+';
  static const operators = [divide, multiply, minus, plus];
}

/// "Papan angka": 5×4 grid, gap 8. Digits on surface, operators and ⌫ on
/// the operator tone in accent, C muted, and Simpan spanning rows 2–4 of the
/// last column.
class Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback? onSave;
  final bool saveEnabled;
  final String saveLabel;

  /// 52 (default) or 56 on tall screens.
  final double rowHeight;

  const Keypad({
    super.key,
    required this.onKey,
    required this.onSave,
    this.saveEnabled = true,
    this.saveLabel = 'Simpan',
    this.rowHeight = 52,
  });

  static const _gap = 8.0;

  void _press(String key) {
    if (Get.isRegistered<HapticsService>()) HapticsService.to.tap();
    onKey(key);
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['7', '8', '9', KeypadKey.divide],
      ['4', '5', '6', KeypadKey.multiply],
      ['1', '2', '3', KeypadKey.minus],
      [KeypadKey.clear, '0', KeypadKey.thousand, KeypadKey.plus],
    ];
    return SizedBox(
      height: rowHeight * 4 + _gap * 3,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                for (var r = 0; r < rows.length; r++) ...[
                  if (r > 0) const SizedBox(height: _gap),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var c = 0; c < 4; c++) ...[
                          if (c > 0) const SizedBox(width: _gap),
                          Expanded(child: _keyFor(rows[r][c])),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: rowHeight,
                  child: _KeyCell(
                    semanticLabel: 'Hapus satu angka',
                    background: colorKeyOperator,
                    onTap: () => _press(KeypadKey.backspace),
                    onLongPress: () => _press(KeypadKey.clear),
                    child:
                        Icon(LucideIcons.delete, size: 22, color: colorAccent),
                  ),
                ),
                const SizedBox(height: _gap),
                Expanded(child: _saveKey()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyFor(String key) {
    final isOp = KeypadKey.operators.contains(key);
    final label = switch (key) {
      KeypadKey.divide => '÷',
      KeypadKey.multiply => '×',
      KeypadKey.minus => '−',
      _ => key,
    };
    final semantic = switch (key) {
      KeypadKey.divide => 'Bagi',
      KeypadKey.multiply => 'Kali',
      KeypadKey.minus => 'Kurang',
      KeypadKey.plus => 'Tambah',
      KeypadKey.clear => 'Bersihkan',
      _ => key,
    };
    return _KeyCell(
      semanticLabel: semantic,
      background: isOp ? colorKeyOperator : colorSurface,
      onTap: () => _press(key),
      child: Text(
        label,
        style: AppText.title1.copyWith(
          fontSize: key == KeypadKey.thousand ? 18 : 22,
          fontWeight: FontWeight.w600,
          color: isOp
              ? colorAccent
              : key == KeypadKey.clear
                  ? colorGrey
                  : colorText,
        ),
      ),
    );
  }

  Widget _saveKey() {
    final enabled = saveEnabled && onSave != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: _KeyCell(
        semanticLabel: saveLabel,
        background: colorAccent,
        onTap: enabled
            ? () {
                if (Get.isRegistered<HapticsService>()) {
                  HapticsService.to.success();
                }
                onSave!();
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 24, color: colorOnAccent),
            const SizedBox(height: 6),
            Text(saveLabel,
                style: AppText.label.copyWith(color: colorOnAccent)),
          ],
        ),
      ),
    );
  }
}

class _KeyCell extends StatelessWidget {
  final String semanticLabel;
  final Color background;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  const _KeyCell({
    required this.semanticLabel,
    required this.background,
    required this.onTap,
    this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Center(child: child),
        ),
      ),
    );
  }
}
