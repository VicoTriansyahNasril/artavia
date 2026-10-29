import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/widgets/commons/common.dart';

/// Transaction row (64 h): round category icon, title (wraps at large text
/// sizes), "Kategori · Rekening · jam", signed amount on the right.
class TxRow extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onTap;

  /// Prefix the subtitle with the date (search / calendar lists).
  final bool showDate;

  /// Search keyword to highlight in the title and subtitle.
  final String? highlight;

  const TxRow(
      {super.key,
      required this.tx,
      this.onTap,
      this.showDate = false,
      this.highlight});

  bool get _isTransfer => tx.type == 'transfer';
  bool get _isIncome => tx.type == 'pemasukan';

  String get title {
    final note = tx.note?.trim() ?? '';
    if (note.isNotEmpty) return note;
    if (_isTransfer) return 'Transfer';
    return tx.categoryName ?? 'Tanpa kategori';
  }

  String get subtitle {
    final time = tx.date == null ? null : DateFormat('HH.mm').format(tx.date!);
    final parts = _isTransfer
        ? ['${tx.accountName ?? '?'} → ${tx.destinationAccountName ?? '?'}']
        : [tx.categoryName ?? 'Tanpa kategori', tx.accountName ?? ''];
    return [
      if (showDate && tx.date != null) IdNames.shortDate(tx.date!),
      ...parts,
      if (time != null) time,
    ].where((e) => e.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final amount = (tx.amount ?? 0).abs();
    final color = _isTransfer
        ? colorAccent
        : themedColor(tx.categoryColorVal, fallbackIndex: 11);
    final amountText = _isTransfer
        ? CurrencyService.to.money(amount)
        : CurrencyService.to.money(_isIncome ? amount : -amount, signed: true);

    return Semantics(
      button: onTap != null,
      label: '$title, $subtitle, $amountText',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CategoryIcon.round(
                  iconKey: _isTransfer ? 'transfer' : tx.categoryIconKey,
                  iconPath: tx.categoryIconPath,
                  iconCode: tx.categoryIconCode,
                  color: color,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                          highlightSpan(
                              title,
                              AppText.body.copyWith(color: colorText),
                              highlight),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppText.caption.muted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      style: AppText.rowAmount
                          .copyWith(color: _isIncome ? colorIncome : colorText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [text] with every case-insensitive match of [query] in accent semibold.
TextSpan highlightSpan(String text, TextStyle style, String? query) {
  final q = query?.trim().toLowerCase() ?? '';
  if (q.isEmpty) return TextSpan(text: text, style: style);
  final lower = text.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final i = lower.indexOf(q, start);
    if (i < 0) break;
    if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
    spans.add(TextSpan(
        text: text.substring(i, i + q.length),
        style: TextStyle(color: colorAccent, fontWeight: FontWeight.w700)));
    start = i + q.length;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return TextSpan(style: style, children: spans);
}
