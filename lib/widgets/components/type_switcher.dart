import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Pengeluaran / Pemasukan / Transfer as three equal segments, so the control
/// is always centred regardless of label length or screen width.
class TransactionTypeSwitcher extends StatelessWidget {
  static const types = ['Pengeluaran', 'Pemasukan', 'Transfer'];

  final String selected;
  final ValueChanged<String> onChanged;

  const TransactionTypeSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static Color toneOf(String type) => switch (type) {
        'Pengeluaran' => colorExpense,
        'Pemasukan' => colorIncome,
        _ => colorAccent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: types.map((type) {
          final active = type == selected;
          final tone = toneOf(type);
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: active ? null : () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? tone.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: active ? tone : colorGrey,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
