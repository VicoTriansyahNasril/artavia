import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/theme_service.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Glass thickness from the Kobalt board (ultra → tebal = more opaque).
enum GlassLevel { ultra, thin, regular, thick }

/// "Kurangi transparansi" (FR-004): glass and orbs fall back to solid fills.
bool get reduceTransparency =>
    Get.isRegistered<ThemeService>() &&
    ThemeService.to.reduceTransparency.value;

Color glassFill(GlassLevel level) {
  final p = AppPalette.current;
  if (reduceTransparency) {
    return level == GlassLevel.thick ? p.surface : p.card;
  }
  return switch (level) {
    GlassLevel.ultra => p.glassUltra,
    GlassLevel.thin => p.glassThin,
    GlassLevel.regular => p.glassRegular,
    GlassLevel.thick => p.glassThick,
  };
}

/// Frosted card: backdrop blur, 1 px border, inset top highlight, soft shadow.
class GlassCard extends StatelessWidget {
  final GlassLevel level;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool shadow;
  final Widget child;

  const GlassCard({
    super.key,
    this.level = GlassLevel.ultra,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(16),
    this.shadow = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final solid = reduceTransparency;
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: glassFill(level),
        borderRadius: borderRadius,
        border: Border.all(color: colorGlassBorder),
        gradient: solid
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.9),
                colors: [colorGlassHighlight, glassFill(level)],
              ),
      ),
      child: Padding(padding: padding, child: child),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                    color: colorShadow,
                    blurRadius: 32,
                    offset: const Offset(0, 8)),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: solid
            ? box
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: box,
              ),
      ),
    );
  }
}

/// Solid card used for list groups and form sections (r16, light shadow).
class KCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final Widget child;

  const KCard({
    super.key,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colorCard,
        borderRadius: borderRadius,
        boxShadow: AppPalette.current.cardShadow,
      ),
      child: child,
    );
  }
}
