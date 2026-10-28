part of 'common.dart';

// Calm "slate" dark palette. Every UI color must come from this file
// (constitution Principle III). Contrast ratios are measured against colorCard.

// ─── Background Layers ────────────────────────────────────────────────────────
/// Deepest background
const Color colorBackground = Color(0xFF111318);

/// Elevated surface (cards, sheets, nav bar)
const Color colorCard = Color(0xFF181B21);

/// Nested surface on top of a card (inputs, chips, tiles)
const Color colorSurface = Color(0xFF20242C);

/// Hairline separator
const Color colorDivider = Color(0xFF2A2F38);

// ─── Text ─────────────────────────────────────────────────────────────────────
/// Primary text — soft off-white to reduce glare (14.2:1)
const Color colorText = Color(0xFFE7E9EE);

/// Secondary text and inactive icons (5.7:1)
const Color colorGrey = Color(0xFF8D94A3);

/// Pure white — only for icons drawn on a colored fill
const Color colorWhite = Color(0xFFFFFFFF);

// ─── Brand Accent ─────────────────────────────────────────────────────────────
/// Soft blue accent (6.8:1)
const Color colorAccent = Color(0xFF7AA2F7);

/// Text/icon color on top of colorAccent, colorExpense or colorIncome fills
const Color colorOnAccent = Color(0xFF0F1115);

/// Tinted accent for selected backgrounds
const Color colorAccentDim = Color(0x247AA2F7);

// ─── Semantic ─────────────────────────────────────────────────────────────────
/// Pemasukan (7.7:1)
const Color colorIncome = Color(0xFF5FBF8F);

/// Pengeluaran (5.9:1)
const Color colorExpense = Color(0xFFE07A7A);

/// Peringatan (8.8:1)
const Color colorWarning = Color(0xFFE0B25C);

/// Translucent black used behind modal overlays / coachmarks
const Color colorScrim = Color(0xFF000000);

// ─── Category & Account Palette ───────────────────────────────────────────────
/// Equal-saturation hues that all read well on the dark background.
const List<Color> categoryPalette = [
  Color(0xFFE07A7A), // coral
  Color(0xFFE59A6B), // apricot
  Color(0xFFE0B25C), // sand
  Color(0xFFA3BE6C), // olive
  Color(0xFF5FBF8F), // mint
  Color(0xFF4FB6B0), // teal
  Color(0xFF5FA8D3), // sky
  Color(0xFF7AA2F7), // blue
  Color(0xFF9D8CE6), // lavender
  Color(0xFFC987C9), // orchid
  Color(0xFFD98AA8), // rose
  Color(0xFF8D94A3), // slate
];

/// Stable palette color for an index (fallback when an item has no color).
Color paletteColorAt(int index) =>
    categoryPalette[index % categoryPalette.length];
