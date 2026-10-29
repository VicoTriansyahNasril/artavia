import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/ambient_orb.dart';

enum ScaffoldLeading { none, back, close }

/// Kobalt screen frame: background, ambient orb, title row (20/600),
/// back/close button and trailing actions; content scrolls under nothing.
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final ScaffoldLeading leading;
  final VoidCallback? onLeading;
  final List<Widget> actions;
  final Widget body;

  /// Sticky footer (CTA bar, keypad sheet) drawn above the body.
  final Widget? bottom;
  final bool showOrb;
  final bool centeredOrb;

  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.leading = ScaffoldLeading.none,
    this.onLeading,
    this.actions = const [],
    required this.body,
    this.bottom,
    this.showOrb = true,
    this.centeredOrb = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null ||
        titleWidget != null ||
        leading != ScaffoldLeading.none ||
        actions.isNotEmpty;
    return Scaffold(
      backgroundColor: colorBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (showOrb) AmbientOrb(centered: centeredOrb),
          SafeArea(
            bottom: bottom == null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasHeader) _header(),
                Expanded(child: body),
                if (bottom != null) bottom!,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (leading != ScaffoldLeading.none)
              KIconButton(
                icon: leading == ScaffoldLeading.back
                    ? LucideIcons.chevronLeft
                    : LucideIcons.x,
                semanticLabel:
                    leading == ScaffoldLeading.back ? 'Kembali' : 'Tutup',
                onPressed: onLeading ?? Get.back,
              )
            else
              const SizedBox(width: 12),
            Expanded(
              child: titleWidget ??
                  Text(
                    title ?? '',
                    style: AppText.title2.copyWith(color: colorText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// 44 px icon-only button with a required screen-reader label.
class KIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const KIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: semanticLabel,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon, size: size, color: color ?? colorText),
    );
  }
}
