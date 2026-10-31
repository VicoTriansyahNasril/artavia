import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artavia/widgets/commons/common.dart';

enum KFieldState { normal, error, warning }

/// Text field (56 h, r14, card fill). Ring: 1 px divider → 1.5 px accent when
/// focused, 1.5 px danger/warning for [state]; [helper] shown below.
class KField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final KFieldState state;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool autofocus;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const KField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.state = KFieldState.normal,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.autofocus = false,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<KField> createState() => _KFieldState();
}

class _KFieldState extends State<KField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KFieldFrame(
      label: widget.label,
      helper: widget.helper,
      state: widget.state,
      focused: _focus.hasFocus,
      child: Row(
        children: [
          if (widget.prefix != null) ...[
            widget.prefix!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              initialValue:
                  widget.controller == null ? widget.initialValue : null,
              focusNode: _focus,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              textInputAction: widget.textInputAction,
              style: AppText.body.copyWith(color: colorText),
              cursorColor: colorAccent,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppText.body.muted,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (widget.suffix != null) ...[
            const SizedBox(width: 8),
            widget.suffix!,
          ],
        ],
      ),
    );
  }
}

/// Shared chrome of [KField] and `KAmountField`: label, the 56 h card box
/// (r14) with its ring — 1 px divider → 1.5 px accent when [focused],
/// 1.5 px danger/warning for [state] — and the helper line.
class KFieldFrame extends StatelessWidget {
  final String? label;
  final String? helper;
  final KFieldState state;
  final bool focused;
  final Widget child;

  const KFieldFrame({
    super.key,
    this.label,
    this.helper,
    this.state = KFieldState.normal,
    this.focused = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tone = switch (state) {
      KFieldState.error => colorDanger,
      KFieldState.warning => colorWarning,
      KFieldState.normal => null,
    };
    final ring = tone != null
        ? BorderSide(color: tone, width: 1.5)
        : focused
            ? BorderSide(color: colorAccent, width: 1.5)
            : BorderSide(color: colorDivider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text(label!, style: AppText.caption.muted),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colorCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(ring),
          ),
          child: child,
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              helper!,
              style: AppText.caption.copyWith(color: tone ?? colorGrey),
            ),
          ),
      ],
    );
  }
}
