import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/currency_format.dart';

/// Global privacy mode (FR-016): hides every amount as "Rp ••••••" on all
/// tabs at once. Starts masked when "Sembunyikan saldo saat dibuka" is on.
///
/// Flipping it rebuilds only the widgets that called [watch] (through
/// [PrivacyScope]), not the whole app.
class PrivacyService extends GetxService {
  static PrivacyService get to => Get.find();

  final masked = false.obs;

  PrivacyService init() {
    _set(SettingsService.to.hideOnOpen);
    return this;
  }

  /// Flips the mask; every [watch]er repaints its amounts.
  void toggle() => _set(!masked.value);

  void _set(bool v) {
    CurrencyService.to.masked = v;
    masked.value = v;
  }

  /// Call from build() of a widget that shows a maskable amount, so it
  /// rebuilds when the mask flips. Harmless without a [PrivacyScope].
  static void watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrivacyScope>();
}

/// Sits above the navigator (see `MyApp`) and notifies [PrivacyService.watch]
/// dependents when [masked] changes.
class PrivacyScope extends InheritedWidget {
  final bool masked;
  const PrivacyScope({super.key, required this.masked, required super.child});

  @override
  bool updateShouldNotify(PrivacyScope old) => old.masked != masked;
}
