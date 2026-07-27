import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:artavia/page/calendar/calendar_controller.dart';
import 'package:artavia/widgets/commons/common.dart';
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
            child: Obx(() => TableCalendar(
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
                        color: colorBlack, fontWeight: FontWeight.bold),
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
                      final hasExpense = (data['expense'] ?? 0) > 0;
                      final hasIncome = (data['income'] ?? 0) > 0;
                      return Positioned(
                        bottom: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasExpense)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                    color: colorExpense,
                                    shape: BoxShape.circle),
                              ),
                            if (hasIncome)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: const BoxDecoration(
                                    color: colorIncome,
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                )),
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

              return ListView.builder(
                itemCount: controller.selectedDayTransactions.length,
                itemBuilder: (context, index) {
                  final tx =
                      controller.selectedDayTransactions[index];
                  return _buildTxItem(tx);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTxItem(TransactionModel tx) {
    final isExpense = tx.type == 'pengeluaran';
    final isTransfer = tx.type == 'transfer';
    final cat = tx.categoryName?.toLowerCase() ?? '';

    IconData icon;
    Color color;
    if (isTransfer) {
      icon = Icons.swap_horiz_rounded;
      color = Colors.blue;
    } else if (cat.contains('makan')) {
      icon = Icons.restaurant_rounded;
      color = Colors.orange;
    } else if (cat.contains('belanja')) {
      icon = Icons.shopping_bag_rounded;
      color = Colors.purple;
    } else if (cat.contains('transport')) {
      icon = Icons.directions_car_rounded;
      color = Colors.teal;
    } else if (cat.contains('gaji') || cat.contains('bonus')) {
      icon = Icons.attach_money_rounded;
      color = colorIncome;
    } else {
      icon = isExpense
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
      color = isExpense ? colorExpense : colorIncome;
    }

    final amount = (tx.amount ?? 0).abs();
    final amtColor = isTransfer
        ? Colors.blue
        : isExpense
            ? colorExpense
            : colorIncome;

    return Container(
      color: colorCard,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        onTap: () => Get.toNamed('/transaction-detail', arguments: {
          'id': tx.id,
          'type': tx.type,
          'amount': amount,
          'category': tx.categoryName,
          'note': tx.note,
          'account': tx.accountName ?? 'CASH',
          'account_id': tx.accountId,
          'destination_account': tx.destinationAccountName,
          'destination_account_id': tx.destinationAccountId,
          'date': tx.date,
        }),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          tx.note?.isNotEmpty == true ? tx.note! : (tx.categoryName ?? '-'),
          style: const TextStyle(
              color: colorWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(tx.categoryName ?? '',
            style: const TextStyle(color: colorGrey, fontSize: 11)),
        trailing: Text(
          '${isExpense ? '-' : isTransfer ? '' : '+'}${CurrencyService.to.formatWithoutSymbol(amount)}',
          style: TextStyle(
              color: amtColor,
              fontSize: 14,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
