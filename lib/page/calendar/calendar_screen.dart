import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:artavia/page/calendar/calendar_controller.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';
import 'package:artavia/model/transaction_model.dart';

class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: const Text('Kalender',
            style: TextStyle(color: colorWhite, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Calendar (fixed)
          Container(
            color: colorCard,
            child: Obx(() {
              // Force Obx to rebuild when dailyData changes (e.g. after async load)
              final _ = controller.dailyData.length;
              return TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: controller.focusedDay.value,
                  selectedDayPredicate: (day) =>
                      isSameDay(controller.selectedDay.value, day),
                  onDaySelected: controller.onDaySelected,
                  onPageChanged: controller.onPageChanged,
                  calendarFormat: CalendarFormat.month,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle:
                        TextStyle(color: colorWhite, fontSize: 15, fontWeight: FontWeight.bold),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: colorWhite),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: colorWhite),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: colorGrey, fontSize: 12),
                    weekendStyle:
                        TextStyle(color: colorExpense, fontSize: 12),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle:
                        const TextStyle(color: colorWhite, fontSize: 13),
                    weekendTextStyle:
                        const TextStyle(color: colorExpense, fontSize: 13),
                    outsideTextStyle:
                        const TextStyle(color: colorGrey, fontSize: 13),
                    selectedDecoration: const BoxDecoration(
                        color: colorAccent, shape: BoxShape.circle),
                    selectedTextStyle: const TextStyle(
                        color: colorOnAccent, fontWeight: FontWeight.bold),
                    todayDecoration: BoxDecoration(
                        border: Border.all(color: colorAccent, width: 1.5),
                        shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(color: colorAccent),
                    cellMargin: const EdgeInsets.all(4),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final key =
                          DateTime(day.year, day.month, day.day);
                      final data = controller.dailyData[key];
                      if (data == null) return null;
                      final expense = data['expense'] ?? 0;
                      final income = data['income'] ?? 0;
                      if (expense == 0 && income == 0) return null;

                      final net = income - expense;
                      if (net == 0) return null;

                      final isIncome = net > 0;
                      final absNet = net.abs();
                      final color = isIncome ? colorIncome : colorExpense;
                      final prefix = isIncome ? '+' : '-';
                      final text = NumberFormat.compact(locale: 'id_ID').format(absNet);

                      return Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '$prefix$text',
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          ),

          // Daily summary bar
          Obx(() {
            final exp = controller.selectedDayExpense;
            final inc = controller.selectedDayIncome;
            if (exp == 0 && inc == 0) return const SizedBox.shrink();
            return Container(
              color: colorBackground,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Obx(() => Text(
                        DateFormat('dd MMM', 'id_ID')
                            .format(controller.selectedDay.value),
                        style: const TextStyle(
                            color: colorGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      )),
                  const Spacer(),
                  if (inc > 0) ...[
                    const Icon(Icons.arrow_downward_rounded,
                        color: colorIncome, size: 14),
                    const SizedBox(width: 4),
                    Text(CurrencyService.to.formatWithoutSymbol(inc),
                        style: const TextStyle(
                            color: colorIncome,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                  if (inc > 0 && exp > 0) const SizedBox(width: 16),
                  if (exp > 0) ...[
                    const Icon(Icons.arrow_upward_rounded,
                        color: colorExpense, size: 14),
                    const SizedBox(width: 4),
                    Text(CurrencyService.to.formatWithoutSymbol(exp),
                        style: const TextStyle(
                            color: colorExpense,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            );
          }),

          // Transaction list for selected day
          Expanded(
            child: Obx(() {
              if (controller.isLoadingDetail.value) {
                return const Center(
                    child: CircularProgressIndicator(color: colorAccent));
              }
              if (controller.selectedDayTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_note_rounded,
                          size: 48,
                          color: colorGrey.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Obx(() => Text(
                            'Tidak ada transaksi pada ${DateFormat('dd MMM', 'id_ID').format(controller.selectedDay.value)}',
                            style: const TextStyle(
                                color: colorGrey, fontSize: 13),
                            textAlign: TextAlign.center,
                          )),
                    ],
                  ),
                );
              }

              return ListView(
                children: controller.selectedDayTransactions.asMap().entries.map((entry) {
                  int i = entry.key;
                  TransactionModel tx = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(
                          color: colorBackground,
                          height: 1,
                          indent: 64,
                        ),
                      TransactionItem(tx: tx),
                    ],
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }
}
