import 'package:get/get.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/utils/date_format.dart';

/// A budgeting period: `start <= date < end`, labelled by the month it ends in.
class Period {
  final int year;
  final int month;
  final DateTime start;
  final DateTime end;

  const Period(this.year, this.month, this.start, this.end);

  /// Period labelled [year]/[month] for a custom month start day.
  /// Start day 25: "Okt" = 25 Sep – 24 Okt.
  factory Period.of(int year, int month, int startDay) {
    final label = DateTime(year, month);
    if (startDay <= 1) {
      return Period(label.year, label.month, label,
          DateTime(label.year, label.month + 1, 1));
    }
    return Period(
        label.year,
        label.month,
        DateTime(label.year, label.month - 1, startDay),
        DateTime(label.year, label.month, startDay));
  }

  /// The period that contains [date].
  factory Period.containing(DateTime date, int startDay) {
    final rollsOver = startDay > 1 && date.day >= startDay;
    final label = DateTime(date.year, date.month + (rollsOver ? 1 : 0));
    return Period.of(label.year, label.month, startDay);
  }

  String get label => '${IdNames.monthShort(month)} $year';
}

/// Active month shared by Riwayat, Grafik (Bulan) and Anggaran (FR-021).
class PeriodService extends GetxService {
  static PeriodService get to => Get.find();

  late final Rx<Period> active;

  int get startDay => SettingsService.to.monthStartDay;

  @override
  void onInit() {
    super.onInit();
    active = Period.containing(DateTime.now(), startDay).obs;
  }

  void select(int year, int month) =>
      active.value = Period.of(year, month, startDay);

  void shift(int months) =>
      select(active.value.year, active.value.month + months);

  /// Recomputes the active period after the start day changed.
  void resetToToday() =>
      active.value = Period.containing(DateTime.now(), startDay);
}
