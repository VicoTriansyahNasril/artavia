import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/commons/common.dart';

/// 52×32 switch (Saklar).
class KSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const KSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        // 44 px tall hit area around the 32 px track.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? colorAccent : colorSwitchOff,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? colorOnAccent : colorSwitchThumbOff,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 22 px checkbox (Centang), r6.
class KCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const KCheck(
      {super.key, required this.value, this.onChanged, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      checked: value,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? colorAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border:
                    value ? null : Border.all(color: colorSwitchOff, width: 2),
              ),
              child: value
                  ? Icon(LucideIcons.check, size: 16, color: colorOnAccent)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 20 px radio.
class KRadio extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const KRadio(
      {super.key, required this.selected, this.onTap, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? colorAccent : colorSwitchOff, width: 2),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: colorAccent, shape: BoxShape.circle))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

enum KTone { accent, warning, danger, income }

Color toneColor(KTone tone) => switch (tone) {
      KTone.accent => colorAccent,
      KTone.warning => colorWarning,
      KTone.danger => colorDanger,
      KTone.income => colorIncome,
    };

/// 6 px progress bar. [value] may exceed 1 (over budget) — the bar caps at
/// full width.
class KProgress extends StatelessWidget {
  final double value;
  final KTone tone;
  final double height;

  const KProgress({
    super.key,
    required this.value,
    this.tone = KTone.accent,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: colorSurface)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: toneColor(tone)),
            ),
          ],
        ),
      ),
    );
  }
}
