import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Segmented control: r12 surface track, 4 px padding, selected pill.
class KSegment<T> extends StatelessWidget {
  final Map<T, String> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  const KSegment({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final light = !AppPalette.current.isDark;
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final e in items.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: e.key == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e.key == value
                          ? (light ? colorCard : colorSurfaceSelected)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: e.key == value && light
                          ? [
                              BoxShadow(
                                  color: colorShadow,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1))
                            ]
                          : null,
                    ),
                    child: Text(
                      e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(
                          color: e.key == value ? colorText : colorGrey),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
