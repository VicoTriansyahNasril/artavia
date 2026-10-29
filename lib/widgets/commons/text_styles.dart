part of 'common.dart';

/// Kobalt type scale (Plus Jakarta Sans, tabular figures).
/// Colors are not baked in: styles inherit the ambient text color unless a
/// caller adds one with `.copyWith(color: …)` or the helpers below.
class AppText {
  AppText._();

  static const String family = 'Plus Jakarta Sans';
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
      fontFamily: family,
      fontSize: 34,
      height: 40 / 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: _tabular);

  /// Big entry amount (Catat / Detail): 36/44.
  static const TextStyle amountXL = TextStyle(
      fontFamily: family,
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: _tabular);

  /// Balance on glass hero cards: 28/34.
  static const TextStyle amountL = TextStyle(
      fontFamily: family,
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: _tabular);

  /// "Rp" prefix next to a large amount: 17/22 medium.
  static const TextStyle currencyPrefix = TextStyle(
      fontFamily: family,
      fontSize: 17,
      height: 22 / 17,
      fontWeight: FontWeight.w500,
      fontFeatures: _tabular);

  static const TextStyle title1 = TextStyle(
      fontFamily: family,
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular);

  static const TextStyle title2 = TextStyle(
      fontFamily: family,
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular);

  static const TextStyle title3 = TextStyle(
      fontFamily: family,
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular);

  static const TextStyle body = TextStyle(
      fontFamily: family,
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular);

  static const TextStyle bodySmall = TextStyle(
      fontFamily: family,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular);

  static const TextStyle label = TextStyle(
      fontFamily: family,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular);

  static const TextStyle caption = TextStyle(
      fontFamily: family,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      fontFeatures: _tabular);

  /// Row amount (14/20 semibold).
  static const TextStyle rowAmount = TextStyle(
      fontFamily: family,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      fontFeatures: _tabular);
}

extension AppTextColor on TextStyle {
  TextStyle get muted => copyWith(color: colorGrey);
  TextStyle get onGlass => copyWith(color: colorTextOnGlass);
  TextStyle get accent => copyWith(color: colorAccent);
  TextStyle get w500 => copyWith(fontWeight: FontWeight.w500);
  TextStyle get w600 => copyWith(fontWeight: FontWeight.w600);
  TextStyle get w700 => copyWith(fontWeight: FontWeight.w700);
}
