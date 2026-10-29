import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

enum StatTone { success, neutral, danger }

class StatItem {
  final String value;
  final String label;
  final StatTone tone;

  const StatItem(
      {required this.value, required this.label, this.tone = StatTone.neutral});
}

/// "Angka ringkas": a row of tiles (success 14 %, surface, danger 14 %),
/// value 20/700.
class StatTiles extends StatelessWidget {
  final List<StatItem> items;

  const StatTiles({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _Tile(item: items[i])),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final StatItem item;
  const _Tile({required this.item});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (item.tone) {
      StatTone.success => (softFill(colorIncome), colorIncome),
      StatTone.danger => (softFill(colorDanger), colorDanger),
      StatTone.neutral => (colorSurface, colorText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(item.value,
                style: AppText.title2
                    .copyWith(color: fg, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 2),
          Text(item.label,
              style: AppText.caption.muted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
