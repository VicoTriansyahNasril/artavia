import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/glass_card.dart';

/// Card (r16) holding rows separated by an inset divider (68 px by default,
/// i.e. aligned after a 40 px icon).
class ListGroup extends StatelessWidget {
  final List<Widget> children;
  final double dividerInset;
  final String? title;
  final Widget? titleAction;

  const ListGroup({
    super.key,
    required this.children,
    this.dividerInset = 68,
    this.title,
    this.titleAction,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: EdgeInsets.only(left: dividerInset),
          child: Divider(height: 1, thickness: 1, color: colorDivider),
        ));
      }
      rows.add(children[i]);
    }
    final card = KCard(child: Column(children: rows));
    if (title == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title!, action: titleAction),
        card,
      ],
    );
  }
}

/// Small muted section heading above a group, with an optional action.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppText.label.copyWith(color: colorGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Settings-style row (≥ 52 h): icon tile, title, subtitle, trailing value,
/// and a trailing control (chevron by default).
class NavRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color? trailingColor;
  final Widget? trailing;
  final bool showChevron;
  final bool danger;
  final VoidCallback? onTap;

  const NavRow({
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingColor,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = danger ? colorDanger : (iconColor ?? colorAccent);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              leading ??
                  (icon != null
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: softFill(tint),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, size: 20, color: tint),
                        )
                      : const SizedBox.shrink()),
              if (leading != null || icon != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.body
                            .copyWith(color: danger ? colorDanger : colorText)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: AppText.caption.muted),
                      ),
                  ],
                ),
              ),
              // Trailing parts may shrink so large text never overflows.
              if (trailingText != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(trailingText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppText.bodySmall
                            .copyWith(color: trailingColor ?? colorGrey)),
                  ),
                ),
              if (trailing != null)
                Flexible(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: trailing!),
                )
              else if (showChevron && onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(LucideIcons.chevronRight,
                      size: 18, color: colorGrey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
