import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class AddTransactionScreen extends GetView<AddTransactionController> {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(child: _buildCategoryGrid()),
          _buildAmountDisplay(),
          _buildNoteRow(),
          _buildQuickAmounts(),
          _buildCustomNumpad(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: colorBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: colorGrey),
        onPressed: () => Get.back(),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTab('Pengeluaran'),
          const SizedBox(width: 24),
          _buildTab('Pemasukan'),
          const SizedBox(width: 24),
          _buildTab('Transfer'),
        ],
      ),
      actions: const [SizedBox(width: 48)],
    );
  }

  Widget _buildTab(String title) {
    return Obx(() {
      final isSelected = controller.currentTab.value == title;
      return GestureDetector(
        onTap: () => controller.onTabChanged(title),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? colorWhite : colorGrey,
                fontSize: 15,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: isSelected ? 18 : 0,
              color: colorAccent,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date
          GestureDetector(
            onTap: () => controller.pickDate(context),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: colorGrey, size: 16),
                const SizedBox(width: 6),
                Obx(() => Text(
                      DateFormat('dd MMM yyyy', 'id_ID')
                          .format(controller.selectedDate.value),
                      style: const TextStyle(color: colorWhite, fontSize: 14),
                    )),
              ],
            ),
          ),
          // Account picker
          GestureDetector(
            onTap: _showAccountBottomSheet,
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: colorGrey, size: 16),
                const SizedBox(width: 6),
                Obx(() => Text(
                      controller.selectedAccountName.value,
                      style: const TextStyle(
                          color: colorWhite, fontSize: 14),
                    )),
                const Icon(Icons.arrow_drop_down,
                    color: colorGrey, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountBottomSheet() {
    Get.bottomSheet(
      Container(
        color: colorCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: colorGrey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Pilih Rekening',
                    style: TextStyle(
                        color: colorWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
            Obx(() => Column(
                  children: controller.availableAccounts.map((acc) {
                    return ListTile(
                      leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: colorGrey),
                      title: Text(acc['name'] as String,
                          style: const TextStyle(color: colorWhite)),
                      onTap: () {
                        controller.selectedAccountId.value = acc['id'] as int;
                        controller.selectedAccountName.value = acc['name'] as String;
                        Get.back();
                      },
                    );
                  }).toList(),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Obx(() {
      if (controller.availableCategories.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.category_outlined,
                  size: 40, color: colorGrey),
              const SizedBox(height: 12),
              const Text('Belum ada kategori',
                  style: TextStyle(color: colorGrey)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.toNamed('/category-management'),
                child: const Text('Tambah Kategori',
                    style: TextStyle(color: colorAccent)),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: controller.availableCategories.length,
        itemBuilder: (context, index) {
          final cat = controller.availableCategories[index];
          return Obx(() {
            final isSelected =
                controller.selectedCategoryId.value == cat['id'];
            return GestureDetector(
              onTap: () =>
                  controller.selectCategory(cat['id'] as int, cat['name'] as String),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? colorAccent
                        : colorCard,
                    child: Icon(
                      cat['icon'] as IconData,
                      color: isSelected ? colorBlack : colorGrey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      color:
                          isSelected ? colorWhite : colorGrey,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          });
        },
      );
    });
  }

  Widget _buildAmountDisplay() {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Obx(() {
        final hasPending = controller.pendingOperator.value.isNotEmpty;
        final isExpense = controller.currentTab.value == 'Pengeluaran';
        final amtColor = isExpense ? colorExpense : colorIncome;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasPending) ...[
              Text(
                '${CurrencyService.to.formatWithoutSymbol(controller.pendingValue.value)} ${controller.pendingOperator.value}',
                style: const TextStyle(color: colorGrey, fontSize: 18),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  CurrencyService.to.formatWithoutSymbol(
                      int.tryParse(controller.amountStr.value) ?? 0),
                  style: TextStyle(
                      color: amtColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNoteRow() {
    return Container(
      color: colorCard,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          const Divider(color: colorBackground, height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.edit_outlined, color: colorGrey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller.noteTextController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Tambahkan catatan...',
                    hintStyle: TextStyle(color: colorGrey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(color: colorWhite, fontSize: 14),
                  onChanged: (val) => controller.note.value = val,
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.noteHistory.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: controller.noteHistory
                      .map((t) => _buildChip(t))
                      .toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return GestureDetector(
      onTap: () => controller.onSuggestionTapped(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colorBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorGrey.withOpacity(0.3)),
        ),
        child: Text(text,
            style: const TextStyle(color: colorGrey, fontSize: 11)),
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Container(
      color: colorBackground,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: controller.quickAmounts.map((amount) {
            return GestureDetector(
              onTap: () => controller.addQuickAmount(amount),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorCard,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: colorGrey.withOpacity(0.2)),
                ),
                child: Text(
                  '+${CurrencyService.to.compact(amount)}',
                  style: const TextStyle(
                      color: colorGrey,
                      fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCustomNumpad(BuildContext context) {
    return Container(
      color: colorCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            _key('7'), _key('8'), _key('9'),
            _key('C', textColor: colorExpense),
          ]),
          Row(children: [
            _key('4'), _key('5'), _key('6'),
            _key('+', textColor: colorAccent),
          ]),
          Row(children: [
            _key('1'), _key('2'), _key('3'),
            _key('-', textColor: colorAccent),
          ]),
          Row(children: [
            _iconKey(Icons.calendar_today_outlined, colorGrey,
                onTap: () => controller.pickDate(context)),
            _key('0'),
            _iconKey(Icons.backspace_outlined, colorGrey,
                onTap: () => controller.onNumpadPressed('delete')),
            // Confirm — colorAccent background
            Expanded(
              child: GestureDetector(
                onTap: () => controller.onNumpadPressed('confirm'),
                child: Container(
                  height: 60,
                  color: colorAccent,
                  child: const Center(
                    child: Icon(Icons.check, color: colorBlack, size: 26),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _key(String label,
      {Color textColor = colorWhite}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.onNumpadPressed(label),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: colorCard,
            border: Border.all(
                color: colorBackground.withOpacity(0.6), width: 0.5),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w400)),
          ),
        ),
      ),
    );
  }

  Widget _iconKey(IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: colorCard,
            border: Border.all(
                color: colorBackground.withOpacity(0.6), width: 0.5),
          ),
          child: Center(child: Icon(icon, color: color, size: 20)),
        ),
      ),
    );
  }
}
