import 'package:get/get.dart';
import 'package:artavia/core/services/theme_service.dart';

/// Ukuran teks (FR-028): follow the system or pick 90–150 %.
class TextSizeController extends GetxController {
  ThemeService get _theme => ThemeService.to;

  static const steps = [
    TextScalePref.small,
    TextScalePref.normal,
    TextScalePref.large,
    TextScalePref.larger,
    TextScalePref.largest,
  ];

  TextScalePref get current => _theme.textScale.value;
  bool get followSystem => current == TextScalePref.system;

  /// Slider position; "system" shows as 100 %.
  int get stepIndex {
    final i = steps.indexOf(current);
    return i < 0 ? 1 : i;
  }

  void setFollowSystem(bool on) =>
      _theme.setTextScale(on ? TextScalePref.system : TextScalePref.normal);

  void setStep(int index) => _theme.setTextScale(steps[index]);

  void reset() => _theme.setTextScale(TextScalePref.normal);
}
