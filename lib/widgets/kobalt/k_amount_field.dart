import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/utils/calc_engine.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/kobalt/k_field.dart';
import 'package:artavia/widgets/kobalt/keypad.dart';
import 'package:artavia/widgets/kobalt/sheet.dart';

/// Money field styled like [KField] that opens the Catat [Keypad] in a sheet
/// instead of the system keyboard, so every amount is typed the same way.
class KAmountField extends StatefulWidget {
  final String? label;
  final String hint;
  final int value;
  final ValueChanged<int> onChanged;
  final String prefix;
  final String? helper;
  final KFieldState state;

  const KAmountField({
    super.key,
    this.label,
    this.hint = '0',
    required this.value,
    required this.onChanged,
    this.prefix = 'Rp',
    this.helper,
    this.state = KFieldState.normal,
  });

  @override
  State<KAmountField> createState() => _KAmountFieldState();
}

class _KAmountFieldState extends State<KAmountField> {
  late int _value = widget.value.abs();
  bool _open = false;

  @override
  void didUpdateWidget(KAmountField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _value = widget.value.abs();
  }

  Future<void> _edit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _open = true);
    final v = await showAmountKeypad(initial: _value, title: widget.label);
    if (!mounted) return;
    setState(() => _open = false);
    if (v == null || v == _value) return;
    setState(() => _value = v);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final text = CurrencyInputFormatter.initial(_value);
    return Semantics(
      button: true,
      label: widget.label,
      value: '${widget.prefix} ${text.isEmpty ? '0' : text}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _edit,
        child: KFieldFrame(
          label: widget.label,
          helper: widget.helper,
          state: widget.state,
          focused: _open,
          child: Row(
            children: [
              Text(widget.prefix, style: AppText.body.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    text.isEmpty ? widget.hint : text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.isEmpty
                        ? AppText.body.muted
                        : AppText.body.copyWith(color: colorText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keypad sheet behind [KAmountField]: big amount, the running expression,
/// and the Catat keypad with "Selesai". Returns null when dismissed.
Future<int?> showAmountKeypad({required int initial, String? title}) {
  final calc = CalcEngine(initial);
  final tall = MediaQuery.sizeOf(Get.context!).height > 760;
  return showSheet<int>(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: StatefulBuilder(
          builder: (context, setState) {
            final money = CurrencyService.to;
            final expression =
                calc.expression(groupSeparator: money.groupSeparator);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(title,
                        style: AppText.title3.copyWith(color: colorText)),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 18,
                  child: Text(expression,
                      textAlign: TextAlign.center,
                      style: AppText.caption.muted),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Rp ',
                        style:
                            AppText.currencyPrefix.copyWith(color: colorGrey)),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                            CalcEngine.group(calc.result < 0 ? 0 : calc.result,
                                money.groupSeparator),
                            style: AppText.amountL.copyWith(color: colorText)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Keypad(
                  saveLabel: 'Selesai',
                  rowHeight: tall ? 56 : 52,
                  onKey: (k) {
                    if (!calc.press(k)) {
                      AppToast.warning('Batas maksimal',
                          'Maksimal ${CalcEngine.maxDigits} digit angka');
                      return;
                    }
                    setState(() {});
                  },
                  onSave: () =>
                      Get.back(result: calc.result < 0 ? 0 : calc.result),
                ),
              ],
            );
          },
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
