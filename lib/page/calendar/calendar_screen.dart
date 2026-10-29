import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/calendar/calendar_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';

/// Kalender (board, FR-024): month summary, grid with grey (expense) and
/// green (income) dots, and the selected day's transactions.
class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Kalender',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: KChip(label: 'Hari ini', onTap: controller.goToday),
        ),
      ],
      body: Obx(() {
        final c = controller;
        c.dailyData.length;
        c.selectedDayTransactions.length;
        final focused = c.focusedDay.value;
        final selected = c.selectedDay.value;
        final money = CurrencyService.to;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${IdNames.monthLong(focused.month)} ${focused.year}',
                      style: AppText.caption.onGlass),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                        money.money(c.monthIncome - c.monthExpense,
                            signed: true),
                        style: AppText.amountL.copyWith(color: colorText)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _figure('Pemasukan', c.monthIncome, colorIncome)),
                      Expanded(
                          child: _figure(
                              'Pengeluaran', c.monthExpense, colorDanger)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            KCard(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                children: [
                  TableCalendar(
                    locale: 'id_ID',
                    firstDay: DateTime.utc(2000, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    focusedDay: focused,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (d) => isSameDay(selected, d),
                    onDaySelected: c.onDaySelected,
                    onPageChanged: c.onPageChanged,
                    calendarFormat: CalendarFormat.month,
                    availableGestures: AvailableGestures.horizontalSwipe,
                    rowHeight: 46,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: AppText.title3.copyWith(color: colorText),
                      leftChevronIcon: Icon(LucideIcons.chevronLeft,
                          size: 20, color: colorText),
                      rightChevronIcon: Icon(LucideIcons.chevronRight,
                          size: 20, color: colorText),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: AppText.caption.muted,
                      weekendStyle: AppText.caption.muted,
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle:
                          AppText.bodySmall.copyWith(color: colorText),
                      weekendTextStyle:
                          AppText.bodySmall.copyWith(color: colorText),
                      todayDecoration: BoxDecoration(
                          color: colorAccentDim, shape: BoxShape.circle),
                      todayTextStyle: AppText.bodySmall.w600.accent,
                      selectedDecoration: BoxDecoration(
                          color: colorAccent, shape: BoxShape.circle),
                      selectedTextStyle:
                          AppText.bodySmall.w600.copyWith(color: colorOnAccent),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, _) {
                        final d =
                            c.dailyData[DateTime(day.year, day.month, day.day)];
                        if (d == null) return null;
                        return Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((d['expense'] ?? 0) > 0) _dot(colorGrey),
                              if ((d['income'] ?? 0) > 0) _dot(colorIncome),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    children: [
                      _legend(colorGrey, 'Pengeluaran'),
                      _legend(colorIncome, 'Pemasukan'),
                    ],
                  ),
                ],
              ),
            ),
            if (c.selectedDayTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                    'Tidak ada transaksi pada ${IdNames.shortDate(selected)}',
                    textAlign: TextAlign.center,
                    style: AppText.bodySmall.muted),
              )
            else
              ListGroup(
                title:
                    '${IdNames.dayLong(selected)}, ${IdNames.shortDate(selected)}',
                titleAction: Text(
                    money.money(c.selectedDayIncome - c.selectedDayExpense,
                        signed: true),
                    style: AppText.caption.w600.copyWith(color: colorGrey)),
                children: [
                  for (final t in c.selectedDayTransactions)
                    TransactionItem(tx: t),
                ],
              ),
          ],
        );
      }),
    );
  }

  static Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(color),
          const SizedBox(width: 4),
          Text(label, style: AppText.caption.muted),
        ],
      );

  static Widget _dot(Color color) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  static Widget _figure(String label, int amount, Color color) => Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caption.onGlass),
                Text(CurrencyService.to.money(amount),
                    style: AppText.rowAmount.copyWith(color: colorText)),
              ],
            ),
          ),
        ],
      );
}
