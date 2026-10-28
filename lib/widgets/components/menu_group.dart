import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Max content width so lists don't stretch edge-to-edge on tablets.
const double maxContentWidth = 600;

/// Centers [child] and caps its width at [maxContentWidth].
class ContentWidth extends StatelessWidget {
  final Widget child;

  const ContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}

/// A titled, rounded group of rows (used by Saya and Pengaturan).
class MenuGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const MenuGroup({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title!.toUpperCase(),
                style: const TextStyle(
                  color: colorGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Material(
            color: colorCard,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 52),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable row: grey icon, title, optional value and chevron.
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final bool danger;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.valueColor,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = danger ? colorExpense : colorText;
    return ListTile(
      minLeadingWidth: 20,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, size: 20, color: danger ? colorExpense : colorGrey),
      title: Text(title, style: TextStyle(color: tone, fontSize: 14)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!,
              style: const TextStyle(color: colorGrey, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!,
                style: TextStyle(color: valueColor ?? colorGrey, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: colorGrey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// A row with a switch, aligned with [MenuTile].
class MenuSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const MenuSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 20,
      contentPadding: const EdgeInsets.only(left: 16, right: 8),
      leading: Icon(icon, size: 20, color: colorGrey),
      title:
          Text(title, style: const TextStyle(color: colorText, fontSize: 14)),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
