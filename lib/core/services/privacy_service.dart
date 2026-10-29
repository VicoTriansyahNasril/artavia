import 'package:get/get.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/currency_format.dart';

/// Global privacy mode (FR-016): hides every amount as "Rp ••••••" on all
/// tabs at once. Starts masked when "Sembunyikan saldo saat dibuka" is on.
class PrivacyService extends GetxService {
  static PrivacyService get to => Get.find();

  final masked = false.obs;

  PrivacyService init() {
    _set(SettingsService.to.hideOnOpen);
    return this;
  }

  /// Flips the mask and repaints every visible amount.
  void toggle() {
    _set(!masked.value);
    Get.forceAppUpdate();
  }

  void _set(bool v) {
    CurrencyService.to.masked = v;
    masked.value = v;
  }
}
