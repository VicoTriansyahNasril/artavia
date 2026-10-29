import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

enum KButtonKind { primary, tonal, text, danger }

/// Kobalt button: Utama (accent fill), Tonal (accent 14 %), Teks, Bahaya
/// (danger outline). Height 48 (default) or 40 (compact). Disabled = 40 %.
class KButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final KButtonKind kind;
  final bool compact;
  final bool expand;

  const KButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = KButtonKind.primary,
    this.compact = false,
    this.expand = true,
  });

  const KButton.tonal({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.compact = true,
    this.expand = false,
  }) : kind = KButtonKind.tonal;

  const KButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
  }) : kind = KButtonKind.text;

  const KButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.compact = false,
    this.expand = true,
  }) : kind = KButtonKind.danger;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, BorderSide side) = switch (kind) {
      KButtonKind.primary => (colorAccent, colorOnAccent, BorderSide.none),
      KButtonKind.tonal => (colorAccentDim, colorAccent, BorderSide.none),
      KButtonKind.text => (
          Colors.transparent,
          colorAccent,
          BorderSide.none,
        ),
      KButtonKind.danger => (
          Colors.transparent,
          colorDanger,
          BorderSide(color: colorDanger, width: 1.5),
        ),
    };
    final enabled = onPressed != null;
    final style = (compact ? AppText.bodySmall : AppText.body)
        .copyWith(fontWeight: FontWeight.w600, color: fg);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 18 : 20, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), side: side),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: compact ? 40 : 48,
                minWidth: 44,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
                child: Center(widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
