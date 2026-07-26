import 'package:flutter/material.dart';

part 'colors.dart';
part 'strings.dart';

class CategoryIcon extends StatelessWidget {
  final String? iconPath;
  final int? iconCode;
  final Color color;
  final double size;

  const CategoryIcon({
    super.key,
    this.iconPath,
    this.iconCode,
    required this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (iconPath != null && iconPath!.isNotEmpty) {
      return Image.asset(
        iconPath!,
        width: size,
        height: size,
        color: color,
      );
    }
    return Icon(
      // ignore: non_const_argument_for_const_parameter
      IconData(iconCode ?? 0xe4fc, fontFamily: 'MaterialIcons'),
      color: color,
      size: size,
    );
  }
}

