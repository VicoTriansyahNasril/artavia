import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/glass_card.dart';
import 'package:artavia/core/services/privacy_service.dart';

/// One column in the hero's 2-col breakdown (e.g. Pemasukan / Pengeluaran).
class HeroFigure {
  final String label;
  final num amount;
  final Color? color;
  final IconData? icon;

  const HeroFigure(
      {required this.label, required this.amount, this.color, this.icon});
}

/// Glass balance card: label 12, "Rp" 17/500 + amount 28/700, 2-col
/// figures, optional insight row under a 1 px glass divider.
class BalanceHero extends StatelessWidget {
  final String label;
  final num amount;
  final List<HeroFigure> figures;
  final String? insight;
  final IconData insightIcon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Optional row above the label (greeting, period navigation).
  final Widget? header;

  const BalanceHero({
    this.header,
    super.key,
    required this.label,
    required this.amount,
    this.figures = const [],
    this.insight,
    this.insightIcon = LucideIcons.trendingDown,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    PrivacyService.watch(context);
    final cs = CurrencyService.to;
    final negative = amount < 0;
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) ...[header!, const SizedBox(height: 10)],
            Row(
              children: [
                Expanded(child: Text(label, style: AppText.caption.onGlass)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              label: '$label ${cs.money(amount, signed: negative)}',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${negative ? CurrencyService.minus : ''}Rp ',
                        style: AppText.currencyPrefix.onGlass),
                    Text(cs.digits(amount),
                        style: AppText.amountL.copyWith(color: colorText)),
                  ],
                ),
              ),
            ),
            if (figures.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final f in figures) Expanded(child: _Figure(figure: f)),
                ],
              ),
            ],
            if (insight != null) ...[
              const SizedBox(height: 14),
              Divider(height: 1, thickness: 1, color: colorGlassHighlight),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(insightIcon, size: 16, color: colorAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(insight!, style: AppText.caption.onGlass),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final HeroFigure figure;
  const _Figure({required this.figure});

  @override
  Widget build(BuildContext context) {
    PrivacyService.watch(context);
    final color = figure.color ?? colorText;
    return Row(
      children: [
        if (figure.icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(color: softFill(color), shape: BoxShape.circle),
            child: Icon(figure.icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(figure.label, style: AppText.caption.onGlass),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(CurrencyService.to.money(figure.amount),
                    style: AppText.rowAmount.copyWith(color: colorText)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
