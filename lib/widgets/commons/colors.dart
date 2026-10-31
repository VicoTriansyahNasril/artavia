part of 'common.dart';

// "Kobalt" palette (specs/002-kobalt-redesign/inputs/kobalt-design-digest.md).
// Every UI color must come from this file (constitution Principle III).
// The public `colorX` names are getters over the active [AppPalette] so the
// whole app can switch between dark and light at runtime.

/// One complete set of color tokens for a brightness.
class AppPalette {
  final Brightness brightness;

  // Layers
  final Color background;
  final Color card;
  final Color surface;
  final Color surfaceSelected;
  final Color keyOperator;
  final Color divider;

  // Text
  final Color text;
  final Color textMuted;
  final Color textOnGlass;

  // Accent & semantic
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color income;
  final Color danger;
  final Color warning;
  final Color switchOff;
  final Color switchThumbOff;

  // Glass layers (fill) + edges. Ultra/thin/regular are lighter than the
  // digest for an iOS-like look; thick stays opaque enough for unblurred
  // dialogs and sheets.
  final Color glassUltra;
  final Color glassThin;
  final Color glassRegular;
  final Color glassThick;
  final Color glassBorder;
  final Color glassHighlight;
  final Color shadow;

  // Ambient orb tint
  final Color orb;

  /// Card elevation shadow (light theme only; dark uses flat cards).
  final List<BoxShadow> cardShadow;

  /// 12 category colors in palette order.
  final List<Color> categories;

  /// Alpha used for soft category fills (14 % dark, 12 % light).
  final double softAlpha;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.surface,
    required this.surfaceSelected,
    required this.keyOperator,
    required this.divider,
    required this.text,
    required this.textMuted,
    required this.textOnGlass,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.income,
    required this.danger,
    required this.warning,
    required this.switchOff,
    required this.switchThumbOff,
    required this.glassUltra,
    required this.glassThin,
    required this.glassRegular,
    required this.glassThick,
    required this.glassBorder,
    required this.glassHighlight,
    required this.shadow,
    required this.orb,
    required this.cardShadow,
    required this.categories,
    required this.softAlpha,
  });

  bool get isDark => brightness == Brightness.dark;

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF111318),
    card: Color(0xFF181B21),
    surface: Color(0xFF20242C),
    surfaceSelected: Color(0xFF2E333D),
    keyOperator: Color(0xFF262B34),
    divider: Color(0xFF2A2F38),
    text: Color(0xFFE7E9EE),
    textMuted: Color(0xFF8D94A3),
    textOnGlass: Color(0xFFA3AAB8),
    accent: Color(0xFF5B8CFF),
    accentSoft: Color(0x245B8CFF),
    onAccent: Color(0xFF0B1020),
    income: Color(0xFF5FBF8F),
    danger: Color(0xFFE07A7A),
    warning: Color(0xFFE0B25C),
    switchOff: Color(0xFF3A404B),
    switchThumbOff: Color(0xFFE7E9EE),
    glassUltra: Color(0x40161A21),
    glassThin: Color(0x5C161A21),
    glassRegular: Color(0x80181C24),
    glassThick: Color(0xD11C2029),
    glassBorder: Color(0x0DFFFFFF),
    glassHighlight: Color(0x1FFFFFFF),
    shadow: Color(0x52000000),
    orb: Color(0x4D5B8CFF),
    cardShadow: [],
    categories: [
      Color(0xFFE07A7A), // coral
      Color(0xFFE59A6B), // apricot
      Color(0xFFE0B25C), // sand
      Color(0xFFA3BE6C), // olive
      Color(0xFF5FBF8F), // mint
      Color(0xFF4FB6B0), // teal
      Color(0xFF5FA8D3), // sky
      Color(0xFF5B8CFF), // blue
      Color(0xFF9D8CE6), // lavender
      Color(0xFFC987C9), // orchid
      Color(0xFFD98AA8), // rose
      Color(0xFF8D94A3), // slate
    ],
    softAlpha: 0.14,
  );

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F6F8),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFEEF0F4),
    surfaceSelected: Color(0xFFFFFFFF),
    keyOperator: Color(0xFFFFFFFF),
    divider: Color(0xFFE3E6EB),
    text: Color(0xFF1B1E24),
    textMuted: Color(0xFF5D6472),
    textOnGlass: Color(0xFF4E5563),
    accent: Color(0xFF2557D6),
    accentSoft: Color(0x1A2557D6),
    onAccent: Color(0xFFFFFFFF),
    income: Color(0xFF1F8657),
    danger: Color(0xFFC2453F),
    warning: Color(0xFFA86E12),
    switchOff: Color(0xFFC9CED6),
    switchThumbOff: Color(0xFFFFFFFF),
    glassUltra: Color(0x4DFFFFFF),
    glassThin: Color(0x6BFFFFFF),
    glassRegular: Color(0x8CFFFFFF),
    glassThick: Color(0xE6FFFFFF),
    glassBorder: Color(0x0F0B0D12),
    glassHighlight: Color(0xB3FFFFFF),
    shadow: Color(0x1A1B1E24),
    orb: Color(0x2E2557D6),
    cardShadow: [
      BoxShadow(color: Color(0x0D1B1E24), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A1B1E24), blurRadius: 12, offset: Offset(0, 4)),
    ],
    categories: [
      Color(0xFFC95A5A),
      Color(0xFFC2703E),
      Color(0xFFA87B1E),
      Color(0xFF6E8A3A),
      Color(0xFF2E9466),
      Color(0xFF24857F),
      Color(0xFF2F7BAA),
      Color(0xFF2557D6),
      Color(0xFF6F5CCF),
      Color(0xFFA0569F),
      Color(0xFFB4587C),
      Color(0xFF6A7180),
    ],
    softAlpha: 0.12,
  );

  /// Active palette. Set by `ThemeService`; dark until it initialises.
  static AppPalette current = dark;
}

/// Category color names in palette order (labels for the color picker).
const List<String> categoryPaletteNames = [
  'Koral',
  'Aprikot',
  'Pasir',
  'Zaitun',
  'Mint',
  'Teal',
  'Langit',
  'Biru',
  'Lavender',
  'Anggrek',
  'Mawar',
  'Batu',
];

/// Canonical (dark) values stored in the DB for category/account colors.
/// The UI maps a stored value to the active theme with [themedColor].
const List<int> categoryPaletteValues = [
  0xFFE07A7A,
  0xFFE59A6B,
  0xFFE0B25C,
  0xFFA3BE6C,
  0xFF5FBF8F,
  0xFF4FB6B0,
  0xFF5FA8D3,
  0xFF5B8CFF,
  0xFF9D8CE6,
  0xFFC987C9,
  0xFFD98AA8,
  0xFF8D94A3,
];

/// App icon (konsep A): blue tile gradient, white "A", gold crossbar.
/// Fixed across themes, like the launcher icon itself.
const Color brandTileTop = Color(0xFF3D72F2);
const Color brandTileBottom = Color(0xFF2252CC);
const Color brandMark = Color(0xFFFFFFFF);
const Color brandGold = Color(0xFFF5C26B);

AppPalette get _p => AppPalette.current;

// ─── Background Layers ────────────────────────────────────────────────────────
Color get colorBackground => _p.background;
Color get colorCard => _p.card;
Color get colorSurface => _p.surface;
Color get colorSurfaceSelected => _p.surfaceSelected;
Color get colorKeyOperator => _p.keyOperator;
Color get colorDivider => _p.divider;

// ─── Text ─────────────────────────────────────────────────────────────────────
Color get colorText => _p.text;
Color get colorGrey => _p.textMuted;
Color get colorTextOnGlass => _p.textOnGlass;

/// Pure white — only for icons drawn on a saturated fill.
const Color colorWhite = Color(0xFFFFFFFF);

// ─── Brand Accent ─────────────────────────────────────────────────────────────
Color get colorAccent => _p.accent;
Color get colorOnAccent => _p.onAccent;
Color get colorAccentDim => _p.accentSoft;

// ─── Semantic ─────────────────────────────────────────────────────────────────
Color get colorIncome => _p.income;
Color get colorExpense => _p.danger;
Color get colorDanger => _p.danger;
Color get colorWarning => _p.warning;
Color get colorSwitchOff => _p.switchOff;
Color get colorSwitchThumbOff => _p.switchThumbOff;

/// Modal scrim behind dialogs (55 % black in both themes).
const Color colorScrim = Color(0x8C000000);

// ─── Glass ────────────────────────────────────────────────────────────────────
Color get colorGlassBorder => _p.glassBorder;
Color get colorGlassHighlight => _p.glassHighlight;
Color get colorShadow => _p.shadow;
Color get colorOrb => _p.orb;

// ─── Category & Account Palette ───────────────────────────────────────────────
List<Color> get categoryPalette => _p.categories;

/// Stable palette color for an index (fallback when an item has no color).
Color paletteColorAt(int index) =>
    categoryPalette[index % categoryPalette.length];

/// Soft fill behind a category icon (14 % dark / 12 % light).
Color softFill(Color c) => c.withValues(alpha: _p.softAlpha);

/// Snaps any stored ARGB value to the nearest canonical palette entry.
int nearestPaletteValue(int colorVal) {
  final c = Color(colorVal);
  var best = categoryPaletteValues.first;
  var bestDist = double.infinity;
  for (final v in categoryPaletteValues) {
    final p = Color(v);
    final dr = p.r - c.r, dg = p.g - c.g, db = p.b - c.b;
    final d = dr * dr + dg * dg + db * db;
    if (d < bestDist) {
      bestDist = d;
      best = v;
    }
  }
  return best;
}

/// Maps a stored (canonical dark) color value to the active theme's variant.
Color themedColor(int? colorVal, {int fallbackIndex = 11}) {
  if (colorVal == null) return paletteColorAt(fallbackIndex);
  final i = categoryPaletteValues.indexOf(nearestPaletteValue(colorVal));
  return categoryPalette[i];
}
