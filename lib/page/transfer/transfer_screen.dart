import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/transfer/transfer_controller.dart';

class TransferScreen extends GetView<TransferController> {
  const TransferScreen({super.key});

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

  // Date row removed

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
                ),
                const SizedBox(height: 4),
                Obx(() => Text('Saldo: ${CurrencyService.to.format(controller.sourceAccountBalance)}', style: const TextStyle(color: colorGrey, fontSize: 11))),
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
                ),
                const SizedBox(height: 4),
                Obx(() => Text('Saldo: ${CurrencyService.to.format(controller.destinationAccountBalance)}', style: const TextStyle(color: colorGrey, fontSize: 11))),
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
        child: SingleChildScrollView(
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: controller.availableAccounts.map((account) {
            return ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: colorWhite),
              title: Text(account['name'] as String, style: const TextStyle(color: colorWhite)),
              subtitle: Text(
                CurrencyService.to.format(account['balance'] as int? ?? 0),
                style: const TextStyle(color: colorGrey, fontSize: 12),
              ),
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
      ),
    );
  }

  Widget _buildAmountRow() {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Left Box: Source (Dipotong)
          Expanded(
            child: Obx(() {
              final isActive = controller.isSynced.value || controller.activeField.value == 'source';
              return GestureDetector(
                onTap: () {
                  controller.setActiveField('source');
                  controller.isNumpadVisible.value = true;
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? colorAccent.withValues(alpha: 0.1) : colorBackground,
                    border: Border.all(color: isActive ? colorAccent : colorGrey.withValues(alpha: 0.2), width: isActive ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dipotong', style: TextStyle(color: colorGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyService.to.formatWithoutSymbol(int.tryParse(controller.sourceAmountStr.value) ?? 0),
                        style: TextStyle(color: isActive ? colorAccent : colorWhite, fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          // Right Box: Destination (Diterima)
          Expanded(
            child: Obx(() {
              final isActive = controller.isSynced.value || controller.activeField.value == 'dest';
              return GestureDetector(
                onTap: () {
                  controller.setActiveField('dest');
                  controller.isNumpadVisible.value = true;
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue.withValues(alpha: 0.1) : colorBackground,
                    border: Border.all(color: isActive ? Colors.blue : colorGrey.withValues(alpha: 0.2), width: isActive ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diterima', style: TextStyle(color: colorGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyService.to.formatWithoutSymbol(int.tryParse(controller.destAmountStr.value) ?? 0),
                        style: TextStyle(color: isActive ? Colors.blue : colorWhite, fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
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
    return Obx(() {
      if (!controller.isNumpadVisible.value) {
        return const SizedBox.shrink();
      }
      return Container(
        color: colorCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              _buildNumpadButton('7', context: context),
              _buildNumpadButton('8', context: context),
              _buildNumpadButton('9', context: context),
              _buildDateKey(context),
            ]),
            Row(children: [
              _buildNumpadButton('4', context: context),
              _buildNumpadButton('5', context: context),
              _buildNumpadButton('6', context: context),
              _buildNumpadButton('+', textColor: colorAccent, context: context),
            ]),
            Row(children: [
              _buildNumpadButton('1', context: context),
              _buildNumpadButton('2', context: context),
              _buildNumpadButton('3', context: context),
              _buildNumpadButton('-', textColor: colorAccent, context: context),
            ]),
            Row(children: [
              _buildNumpadButton('0', context: context),
              _buildNumpadButton('000', context: context),
              _buildNumpadButton('delete', isIcon: true, iconData: Icons.backspace_outlined, context: context),
              _buildNumpadButton('confirm', isIcon: true, iconData: Icons.check, bgColor: colorAccent, iconColor: colorOnAccent, context: context),
            ]),
          ],
        ),
      );
    });
  }

  Widget _buildDateKey(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.pickDate(context),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: colorCard,
            border: Border.all(
                color: colorBackground.withValues(alpha: 0.6), width: 0.5),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: colorAccent, size: 14),
                const SizedBox(width: 4),
                Obx(() => Text(
                      DateFormatter.formatWithRelative(controller.selectedDate.value)
                          .replaceAll(RegExp(r' \(\d{2} [a-zA-Z]+ \d{4}\)'), ''), // Hide full date if 'Hari Ini', 'Besok' etc
                      style: const TextStyle(color: colorAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ),
        ),
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
