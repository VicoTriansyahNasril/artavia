import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:artavia/core/utils/date_format.dart';
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
          Expanded(child: _buildCategoryGrid()),
          Obx(() {
            if (controller.selectedCategoryId.value == null) {
              return const SizedBox.shrink();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAmountDisplay(),
                _buildNoteRow(),
                _buildQuickAmounts(),
                _buildCustomNumpad(context),
              ],
            );
          }),
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

  // Top bar removed
  void _showAccountBottomSheet() {
    Get.bottomSheet(
      Material(
        color: colorCard,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: colorGrey.withValues(alpha: 0.4),
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
            Flexible(
              child: SingleChildScrollView(
                child: Obx(() => Column(
                      children: controller.availableAccounts.map((acc) {
                        return ListTile(
                          leading: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: colorGrey),
                          title: Text(acc['name'] as String,
                              style: const TextStyle(color: colorWhite)),
                          subtitle: Text(
                              CurrencyService.to.format(acc['balance'] as int? ?? 0),
                              style: const TextStyle(color: colorGrey, fontSize: 12)),
                          onTap: () {
                            controller.selectedAccountId.value = acc['id'] as int;
                            controller.selectedAccountName.value = acc['name'] as String;
                            Get.back();
                          },
                        );
                      }).toList(),
                    )),
              ),
            ),
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
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 85,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: controller.availableCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == controller.availableCategories.length) {
            return GestureDetector(
              onTap: () {
                Get.toNamed('/add-category')?.then((_) {
                  controller.onTabChanged(controller.currentTab.value);
                });
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorCard,
                    child: Icon(Icons.add, color: colorGrey, size: 24),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tambah',
                    style: TextStyle(color: colorGrey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }

          final cat = controller.availableCategories[index];
          return Obx(() {
            final isSelected =
                controller.selectedCategoryId.value == cat['id'];
            return GestureDetector(
              onTap: () =>
                  controller.selectCategory(cat['id'] as int, cat['name'] as String),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? colorAccent
                        : colorCard,
                    child: CategoryIcon(
                      iconCode: cat['icon_code'] as int?,
                      iconPath: cat['icon_path'] as String?,
                      color: isSelected ? colorOnAccent : colorGrey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      cat['name'] as String,
                      style: TextStyle(
                        color: isSelected ? colorAccent : colorGrey,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
    return GestureDetector(
      onTap: () => controller.toggleNumpad(),
      child: Container(
        color: colorCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Obx(() {
          final hasPending = controller.pendingOperator.value.isNotEmpty;
          final isExpense = controller.currentTab.value == 'Pengeluaran';
          final amtColor = isExpense ? colorExpense : colorIncome;

          return Row(
            children: [
              // Account picker
            GestureDetector(
              onTap: _showAccountBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: colorGrey, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            controller.selectedAccountName.value,
                            style: const TextStyle(
                                color: colorWhite, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: colorGrey, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saldo: ${CurrencyService.to.format(controller.selectedAccountBalance)}',
                      style: const TextStyle(color: colorGrey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Amount Display
            Expanded(
              child: Row(
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
              ),
            ),
          ],
        );
      }),
    ));
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
          border: Border.all(color: colorGrey.withValues(alpha: 0.3)),
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
                      color: colorGrey.withValues(alpha: 0.2)),
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
              _key('7'), _key('8'), _key('9'),
              _buildDateKey(context),
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
              _key('0'),
              _key('000'),
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
                    child: Icon(Icons.check, color: colorOnAccent, size: 26),
                  ),
                ),
              ),
              ),
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
                          .replaceAll(RegExp(r' \(\d{2} [a-zA-Z]+ \d{4}\)'), ''),
                      style: const TextStyle(color: colorAccent, fontSize: 13, fontWeight: FontWeight.bold),
                    )),
              ],
            ),
          ),
        ),
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
                color: colorBackground.withValues(alpha: 0.6), width: 0.5),
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
                color: colorBackground.withValues(alpha: 0.6), width: 0.5),
          ),
          child: Center(child: Icon(icon, color: color, size: 20)),
        ),
      ),
    );
  }
}
