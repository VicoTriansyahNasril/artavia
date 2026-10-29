import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Pill chip (34 h). Selected = accent 14 % + accent text + 1.5 px ring.
class KChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool showCheck;
  final VoidCallback? onTap;

  const KChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.showCheck = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? colorAccent : colorText;
    // Visual chip is 34 px; the 5 px padding makes the hit area 44 px.
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Material(
            color: selected ? colorAccentDim : colorSurface,
            shape: StadiumBorder(
              side: selected
                  ? BorderSide(color: colorAccent, width: 1.5)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 34, minWidth: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected && showCheck) ...[
                        Icon(LucideIcons.check, size: 16, color: fg),
                        const SizedBox(width: 6),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 16, color: fg),
                        const SizedBox(width: 6),
                      ],
                      Text(label, style: AppText.label.copyWith(color: fg)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
