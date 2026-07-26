import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/page/transfer/transfer_controller.dart';

class TransferScreen extends StatelessWidget {
  final TransferController controller = Get.put(TransferController());

  TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: const Text('Transfer', style: TextStyle(color: colorWhite, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildDateRow(context),
          const SizedBox(height: 8),
          _buildTransferAccountsCard(),
          const Spacer(),
          _buildAmountRow(),
          const SizedBox(height: 1),
          _buildNoteRow(),
          _buildCustomNumpad(context),
        ],
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () => controller.pickDate(context),
            child: Row(
              children: [
                Obx(() {
                  String formatted = DateFormat('dd MMM yyyy', 'id_ID').format(controller.selectedDate.value);
                  return Text(
                    formatted,
                    style: const TextStyle(color: colorWhite, fontSize: 16),
                  );
                }),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, color: colorGrey, size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransferAccountsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorGrey.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dari
          InkWell(
            onTap: () => _showAccountSheet(true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dari', style: TextStyle(color: colorGrey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: colorAccent, size: 20),
                    const SizedBox(width: 8),
                    Obx(() => Text(controller.sourceAccountName.value, style: const TextStyle(color: colorWhite, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_drop_down, color: colorGrey),
                  ],
                )
              ],
            ),
          ),
          // Panah
          const Icon(Icons.arrow_forward_rounded, color: colorWhite),
          // Ke
          InkWell(
            onTap: () => _showAccountSheet(false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Ke', style: TextStyle(color: colorGrey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Obx(() => Text(controller.destinationAccountName.value, style: const TextStyle(color: colorWhite, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_drop_down, color: colorGrey),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountSheet(bool isSource) {
    Get.bottomSheet(
      Material(
        color: colorCard,
        child: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.availableAccounts.map((account) {
            return ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: colorWhite),
              title: Text(account['name'] as String, style: const TextStyle(color: colorWhite)),
              onTap: () {
                if (isSource) {
                  controller.sourceAccountId.value = account['id'] as int;
                  controller.sourceAccountName.value = account['name'] as String;
                } else {
                  controller.destinationAccountId.value = account['id'] as int;
                  controller.destinationAccountName.value = account['name'] as String;
                }
                Get.back();
              },
            );
          }).toList(),
        )),
      ),
    );
  }

  Widget _buildAmountRow() {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('Jumlah Transfer', style: TextStyle(color: colorGrey, fontSize: 14)),
          const SizedBox(height: 8),
          Obx(() => Text(
            CurrencyService.to.format(int.tryParse(controller.amountStr.value) ?? 0),
            style: const TextStyle(color: Colors.blue, fontSize: 40, fontWeight: FontWeight.bold),
          )),
        ],
      ),
    );
  }

  Widget _buildNoteRow() {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: colorGrey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller.noteTextController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Pesan (opsional)',
                    hintStyle: TextStyle(color: colorGrey),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: colorWhite),
                  onChanged: (val) => controller.note.value = val,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() => Row(
              children: controller.noteHistory.map((text) => _buildSuggestChip(text)).toList(),
            )),
          )
        ],
      ),
    );
  }

  Widget _buildSuggestChip(String text) {
    return InkWell(
      onTap: () => controller.onSuggestionTapped(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorGrey.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: const TextStyle(color: colorGrey, fontSize: 12)),
      ),
    );
  }

  Widget _buildCustomNumpad(BuildContext context) {
    return Container(
      color: colorCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildNumpadButton('7', context: context),
              _buildNumpadButton('8', context: context),
              _buildNumpadButton('9', context: context),
              _buildNumpadButton('calendar', isIcon: true, iconData: Icons.calendar_today, context: context),
            ],
          ),
          Row(
            children: [
              _buildNumpadButton('4', context: context),
              _buildNumpadButton('5', context: context),
              _buildNumpadButton('6', context: context),
              _buildNumpadButton('+', context: context),
            ],
          ),
          Row(
            children: [
              _buildNumpadButton('1', context: context),
              _buildNumpadButton('2', context: context),
              _buildNumpadButton('3', context: context),
              _buildNumpadButton('-', context: context),
            ],
          ),
          Row(
            children: [
              _buildNumpadButton('C', textColor: colorExpense, context: context),
              _buildNumpadButton('0', context: context),
              _buildNumpadButton('delete', isIcon: true, iconData: Icons.backspace_outlined, context: context),
              _buildNumpadButton('confirm', isIcon: true, iconData: Icons.check, bgColor: Colors.blue, iconColor: colorWhite, context: context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(String keyStr, {
    bool isIcon = false,
    IconData? iconData,
    Color textColor = colorWhite,
    Color? bgColor,
    Color? iconColor,
    required BuildContext context,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (keyStr == 'calendar') {
            controller.pickDate(context);
          } else {
            controller.onNumpadPressed(keyStr);
          }
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: bgColor ?? colorCard,
            border: Border.all(color: colorBackground, width: 0.5),
          ),
          child: Center(
            child: isIcon
                ? Icon(iconData, color: iconColor ?? colorGrey)
                : Text(keyStr, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
