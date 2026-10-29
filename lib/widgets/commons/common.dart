import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/icon_registry.dart';

export 'package:artavia/widgets/commons/icon_registry.dart';

part 'colors.dart';
part 'strings.dart';
part 'text_styles.dart';

/// Round, softly tinted category/account icon (board: "Baris daftar").
///
/// Prefers [iconKey] (Lucide, v12+). Legacy rows without a key are mapped
/// through [IconRegistry.legacyToKey] so nothing renders blank.
class CategoryIcon extends StatelessWidget {
  final String? iconKey;
  final String? iconPath;
  final int? iconCode;
  final Color color;

  /// Glyph size. The tinted circle is drawn only when [diameter] is set.
  final double size;
  final double? diameter;

  const CategoryIcon({
    super.key,
    this.iconKey,
    this.iconPath,
    this.iconCode,
    required this.color,
    this.size = 24.0,
    this.diameter,
  });

  /// Circle variant used in lists and pickers.
  const CategoryIcon.round({
    super.key,
    this.iconKey,
    this.iconPath,
    this.iconCode,
    required this.color,
    double diameter = 40,
  })  : diameter = diameter,
        size = diameter * 0.5;

  String get resolvedKey => IconRegistry.contains(iconKey)
      ? iconKey!
      : IconRegistry.legacyToKey(iconPath: iconPath, iconCode: iconCode);

  @override
  Widget build(BuildContext context) {
    final glyph =
        Icon(IconRegistry.byKey(resolvedKey).icon, color: color, size: size);
    if (diameter == null) return glyph;
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: softFill(color), shape: BoxShape.circle),
      child: glyph,
    );
  }
}
