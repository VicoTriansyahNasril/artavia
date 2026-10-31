import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/ambient_orb.dart';

/// Loading screen (design "Loading · konsep A") shown while services start:
/// the app icon whose gold crossbar draws in and out, the wordmark, and a
/// sliding progress bar. Runs as its own tiny app before [MyApp] exists.
class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Crossbar: 1.4 s, alternate. Progress bar: 1.2 s, loop.
  late final _bar = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  late final _load = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _bar.value = 1;
      _load.stop();
    } else {
      if (!_bar.isAnimating) _bar.repeat(reverse: true);
      if (!_load.isAnimating) _load.repeat();
    }
  }

  @override
  void dispose() {
    _bar.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorBackground,
      child: Stack(
        children: [
          const AmbientOrb(centered: true),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Artavia',
                  image: true,
                  child: _AppIcon(progress: _bar),
                ),
                const SizedBox(height: 20),
                Text('Artavia',
                    style: AppText.amountL.copyWith(color: colorText)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 72 + MediaQuery.paddingOf(context).bottom,
            child: Column(
              children: [
                Semantics(
                  label: 'Memuat data',
                  child: _LoadBar(progress: _load),
                ),
                const SizedBox(height: 10),
                Text('Menyiapkan datamu…',
                    style: AppText.caption.copyWith(color: colorGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 112 px tile, r25, 160° blue gradient, white "A" with an animated gold bar.
class _AppIcon extends StatelessWidget {
  final Animation<double> progress;
  const _AppIcon({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment(-0.34, -0.94),
          end: Alignment(0.34, 0.94),
          colors: [brandTileTop, brandTileBottom],
        ),
        boxShadow: [
          BoxShadow(
              color: colorShadow, blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border:
            Border(top: BorderSide(color: brandMark.withValues(alpha: 0.18))),
      ),
      child: CustomPaint(painter: _MarkPainter(progress)),
    );
  }
}

/// Draws the mark in the design's 100×100 box: "A" stroke, dim crossbar
/// track, and the gold crossbar growing from a dot to full width.
class _MarkPainter extends CustomPainter {
  final Animation<double> progress;
  _MarkPainter(this.progress) : super(repaint: progress);

  // Dash grows 0 → 24 over the first 60 % of each pass, then holds.
  static const _ease = Cubic(.3, .7, .3, 1);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
        Path()
          ..moveTo(28, 76)
          ..lineTo(50, 24)
          ..lineTo(72, 76),
        stroke(brandMark, 10));
    canvas.drawLine(const Offset(38, 58), const Offset(62, 58),
        stroke(brandMark.withValues(alpha: 0.32), 7));

    final t = progress.value;
    final dash = 24 * (t < .6 ? _ease.transform(t / .6) : 1.0);
    canvas.drawLine(const Offset(38, 58), Offset(38 + math.min(16.0, dash), 58),
        stroke(brandGold, 7));
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}

/// 120×4 track with a 40 % accent pill sliding −100 % → 250 %.
class _LoadBar extends StatelessWidget {
  final Animation<double> progress;
  const _LoadBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    // Captured once: the saved theme may load while the bar is running.
    final bar = colorAccent;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 120,
        height: 4,
        child: ColoredBox(
          color: colorSurface,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final x = -1 + 3.5 * Curves.easeInOut.transform(progress.value);
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: .4,
                child: FractionalTranslation(
                  translation: Offset(x, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: bar,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
