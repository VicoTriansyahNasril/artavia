import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/widgets/commons/common.dart';

enum ThemePref { system, dark, light }

/// Text size choices (Pengaturan › Ukuran teks). `null` scale = follow system.
enum TextScalePref {
  system(null, 'Ikuti sistem'),
  small(0.9, '90 %'),
  normal(1.0, '100 %'),
  large(1.15, '115 %'),
  larger(1.3, '130 %'),
  largest(1.5, '150 %');

  final double? scale;
  final String label;
  const TextScalePref(this.scale, this.label);

  static TextScalePref fromKey(String? key) => TextScalePref.values
      .firstWhere((e) => e.name == key, orElse: () => TextScalePref.system);
}

/// Owns theme mode, text size and "Kurangi transparansi" (FR-004/028/031).
class ThemeService extends GetxService with WidgetsBindingObserver {
  static ThemeService get to => Get.find();

  static const keyThemeMode = 'theme_mode';
  static const keyTextScale = 'text_scale';
  static const keyReduceTransparency = 'reduce_transparency';

  final pref = ThemePref.system.obs;
  final textScale = TextScalePref.system.obs;
  final reduceTransparency = false.obs;

  ThemeService init() {
    final s = SettingsService.to;
    pref.value = ThemePref.values.firstWhere(
        (e) => e.name == s.get(keyThemeMode),
        orElse: () => ThemePref.system);
    textScale.value = TextScalePref.fromKey(s.get(keyTextScale));
    reduceTransparency.value = s.get(keyReduceTransparency) == 'true';
    AppPalette.current = palette;
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Brightness get _platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  Brightness get brightness => switch (pref.value) {
        ThemePref.dark => Brightness.dark,
        ThemePref.light => Brightness.light,
        ThemePref.system => _platformBrightness,
      };

  AppPalette get palette =>
      brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

  ThemeMode get themeMode => switch (pref.value) {
        ThemePref.dark => ThemeMode.dark,
        ThemePref.light => ThemeMode.light,
        ThemePref.system => ThemeMode.system,
      };

  String get themeLabel => switch (pref.value) {
        ThemePref.dark => 'Gelap',
        ThemePref.light => 'Terang',
        ThemePref.system => 'Ikuti sistem',
      };

  /// Text scaler for the app; `null` keeps the platform scaler.
  TextScaler? get textScaler {
    final s = textScale.value.scale;
    return s == null ? null : TextScaler.linear(s);
  }

  Future<void> setTheme(ThemePref p) async {
    pref.value = p;
    await SettingsService.to.set(keyThemeMode, p.name);
    _apply();
  }

  Future<void> setTextScale(TextScalePref s) async {
    textScale.value = s;
    await SettingsService.to.set(keyTextScale, s.name);
    Get.forceAppUpdate();
  }

  Future<void> setReduceTransparency(bool v) async {
    reduceTransparency.value = v;
    await SettingsService.to.set(keyReduceTransparency, '$v');
    Get.forceAppUpdate();
  }

  void _apply() {
    final next = palette;
    if (identical(AppPalette.current, next)) {
      Get.changeThemeMode(themeMode);
      return;
    }
    AppPalette.current = next;
    Get.changeThemeMode(themeMode);
    Get.forceAppUpdate();
  }

  @override
  void didChangePlatformBrightness() {
    if (pref.value == ThemePref.system) _apply();
  }
}
