import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/glass_card.dart';

/// The one soft accent glow per screen (320 px, top-right, accent 30 %/18 %).
/// Drawn as a radial gradient — cheaper than a real 60 px blur.
class AmbientOrb extends StatelessWidget {
  /// `true` centers a larger orb (PIN screen).
  final bool centered;

  const AmbientOrb({super.key, this.centered = false});

  @override
  Widget build(BuildContext context) {
    if (reduceTransparency) return const SizedBox.shrink();
    final size = centered ? 360.0 : 320.0;
    final orb = IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [colorOrb, colorOrb.withValues(alpha: 0)],
            stops: const [0, 1],
          ),
        ),
      ),
    );
    if (centered) {
      return Positioned.fill(
          child: Align(alignment: const Alignment(0, -0.35), child: orb));
    }
    return Positioned(right: -90, top: -80, child: orb);
  }
}
