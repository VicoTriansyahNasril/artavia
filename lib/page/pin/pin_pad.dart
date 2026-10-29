import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/haptics_service.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// PIN entry (board "PIN"): lock tile, title, [length] dots (red on
/// error), message, round 72 px keys, optional fingerprint key and
/// "Lupa PIN?". Calls [onCompleted] once all digits are entered.
class PinPad extends StatefulWidget {
  final String title;
  final String? message;
  final bool isError;
  final bool busy;
  final int length;
  final ValueChanged<String> onCompleted;
  final VoidCallback? onBiometric;
  final VoidCallback? onForgot;

  const PinPad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.length = 6,
    this.message,
    this.isError = false,
    this.busy = false,
    this.onBiometric,
    this.onForgot,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _press(String key) {
    if (widget.busy) return;
    if (Get.isRegistered<HapticsService>()) HapticsService.to.tap();
    setState(() {
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < widget.length) {
        _pin += key;
      }
    });
    if (_pin.length == widget.length) {
      final entered = _pin;
      setState(() => _pin = '');
      widget.onCompleted(entered);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
              color: colorAccentDim, borderRadius: BorderRadius.circular(20)),
          child: Icon(LucideIcons.lock, color: colorAccent, size: 28),
        ),
        const SizedBox(height: 16),
        Text(widget.title,
            textAlign: TextAlign.center,
            style: AppText.title2.copyWith(color: colorText)),
        const SizedBox(height: 20),
        _Dots(
          length: widget.length,
          filled: _pin.length,
          busy: widget.busy,
          error: widget.isError,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Semantics(
            liveRegion: true,
            child: Text(
              widget.message ?? '',
              textAlign: TextAlign.center,
              style: AppText.bodySmall
                  .copyWith(color: widget.isError ? colorDanger : colorGrey),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Keys(onPressed: _press, onBiometric: widget.onBiometric),
        if (widget.onForgot != null) ...[
          const SizedBox(height: 8),
          KButton.text(
            label: 'Lupa PIN?',
            expand: false,
            onPressed: widget.onForgot,
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int length;
  final int filled;
  final bool busy;
  final bool error;

  const _Dots({
    required this.length,
    required this.filled,
    required this.busy,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Semantics(
      label: '$filled dari $length angka',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(length, (i) {
          final on = i < filled;
          final tone = error && filled == 0 ? colorDanger : colorAccent;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on || (error && filled == 0) ? tone : Colors.transparent,
              border: Border.all(
                  color: on || error ? tone : colorSwitchOff, width: 1.5),
            ),
          );
        }),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  final ValueChanged<String> onPressed;
  final VoidCallback? onBiometric;

  const _Keys({required this.onPressed, this.onBiometric});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['bio', '0', 'del'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final k in row)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _key(k),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String k) {
    if (k == 'bio') {
      if (onBiometric == null) return const SizedBox(width: 72, height: 72);
      return _RoundKey(
        semantic: 'Buka dengan sidik jari',
        onTap: onBiometric!,
        filled: false,
        child: Icon(LucideIcons.fingerprint, size: 28, color: colorAccent),
      );
    }
    if (k == 'del') {
      return _RoundKey(
        semantic: 'Hapus satu angka',
        onTap: () => onPressed('del'),
        filled: false,
        child: Icon(LucideIcons.delete, size: 24, color: colorGrey),
      );
    }
    return _RoundKey(
      semantic: k,
      onTap: () => onPressed(k),
      child: Text(k,
          style: AppText.title1
              .copyWith(fontWeight: FontWeight.w500, color: colorText)),
    );
  }
}

class _RoundKey extends StatelessWidget {
  final String semantic;
  final VoidCallback onTap;
  final Widget child;
  final bool filled;

  const _RoundKey({
    required this.semantic,
    required this.onTap,
    required this.child,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Material(
        color: filled ? colorSurface : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Center(child: child)),
        ),
      ),
    );
  }
}
