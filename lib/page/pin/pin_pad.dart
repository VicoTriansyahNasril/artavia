import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

const pinLength = 4;

/// Four dots + numeric keypad. Calls [onCompleted] once 4 digits are entered
/// and clears itself; [busy] disables input while a PIN is being checked.
class PinPad extends StatefulWidget {
  final String title;
  final String? message;
  final bool isError;
  final bool busy;
  final ValueChanged<String> onCompleted;

  const PinPad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.message,
    this.isError = false,
    this.busy = false,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _press(String key) {
    if (widget.busy) return;
    setState(() {
      if (key == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < pinLength) {
        _pin += key;
      }
    });
    if (_pin.length == pinLength) {
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
        const Icon(Icons.lock_outline_rounded, color: colorAccent, size: 36),
        const SizedBox(height: 16),
        Text(widget.title,
            style: const TextStyle(
                color: colorText, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: Text(
            widget.message ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: widget.isError ? colorExpense : colorGrey, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        _Dots(filled: _pin.length, busy: widget.busy),
        const SizedBox(height: 36),
        _Keypad(onPressed: _press),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  final int filled;
  final bool busy;

  const _Dots({required this.filled, required this.busy});

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pinLength, (i) {
        final on = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? colorAccent : Colors.transparent,
            border: Border.all(color: on ? colorAccent : colorGrey, width: 1.5),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onPressed;

  const _Keypad({required this.onPressed});

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '0',
    'del'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        children: _keys.map((k) {
          if (k.isEmpty) return const SizedBox();
          return InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () => onPressed(k),
            child: Center(
              child: k == 'del'
                  ? const Icon(Icons.backspace_outlined, color: colorGrey)
                  : Text(k,
                      style: const TextStyle(
                          color: colorText,
                          fontSize: 26,
                          fontWeight: FontWeight.w500)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
