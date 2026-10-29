import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/glass_card.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

/// Bottom navigation (84 h, glass reguler): Transaksi · Laporan · [Catat] ·
/// Rekening · Pengaturan. Active = accent label + 56×28 accent-14 % pill.
class KBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onCatat;

  /// Optional keys per tab index (coach-mark targets).
  final Map<int, Key> itemKeys;

  const KBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.onCatat,
    this.itemKeys = const {},
  });

  static const _items = [
    _NavItem(LucideIcons.receiptText, 'Transaksi'),
    _NavItem(LucideIcons.chartPie, 'Laporan'),
    _NavItem(LucideIcons.wallet, 'Rekening'),
    _NavItem(LucideIcons.settings, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return GlassCard(
      level: GlassLevel.regular,
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.only(bottom: bottomInset),
      shadow: false,
      child: SizedBox(
        height: 84 - 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _slot(0),
            _slot(1),
            Expanded(child: _CatatButton(onTap: onCatat)),
            _slot(2),
            _slot(3),
          ],
        ),
      ),
    );
  }

  Widget _slot(int i) {
    final item = _items[i];
    final active = i == index;
    final color = active ? colorAccent : colorGrey;
    return Expanded(
      key: itemKeys[i],
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onTap(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                height: 28,
                decoration: BoxDecoration(
                  color: active ? colorAccentDim : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, size: 20, color: color),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: AppText.caption.copyWith(
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Center "Catat" button: 52 px accent circle raised 12 px into the bar.
class _CatatButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CatatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Catat transaksi',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -12),
            child: Material(
              color: colorAccent,
              shape: const CircleBorder(),
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(LucideIcons.plus, size: 26, color: colorOnAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
