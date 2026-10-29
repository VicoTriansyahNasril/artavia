import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/transfer/transfer_section.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Catat (board "Catat transaksi"): segment, amount + expression, category
/// grid (or the transfer section), and a glass sheet with account, date,
/// note and the keypad.
class AddTransactionScreen extends GetView<AddTransactionController> {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.close,
      title: controller.isEdit ? 'Ubah transaksi' : 'Catat transaksi',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: KSegment<String>(
                items: {for (final t in AddTransactionController.tabs) t: t},
                value: controller.currentTab.value,
                onChanged: controller.onTabChanged,
              ),
            ),
            Expanded(
              child: controller.isTransfer
                  ? const TransferSection()
                  : const _EntryBody(),
            ),
          ],
        );
      }),
      bottom: const _KeypadSheet(),
    );
  }
}

/// Amount + category grid for Pengeluaran / Pemasukan.
class _EntryBody extends GetView<AddTransactionController> {
  const _EntryBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const AmountDisplay(),
        const SizedBox(height: 8),
        SectionHeader(
          title: 'Kategori',
          action: KButton.text(
            label: 'Lihat semua',
            compact: true,
            expand: false,
            onPressed: () => _showAllCategories(context),
          ),
        ),
        Obx(() => _CategoryGrid(
              categories: controller.gridCategories,
              selectedId: controller.selectedCategoryId.value,
              onSelect: controller.selectCategory,
              onAdd: _addCategory,
            )),
      ],
    );
  }

  Future<void> _addCategory() async {
    await Get.toNamed(addCategoryRoute, arguments: {
      'type': controller.currentTab.value == 'Pemasukan'
          ? 'pemasukan'
          : 'pengeluaran',
    });
    await controller.reloadCategories();
  }

  void _showAllCategories(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Semua kategori',
                    style: AppText.title3.copyWith(color: colorText)),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Obx(() => _CategoryGrid(
                          categories: controller.rankedCategories,
                          selectedId: controller.selectedCategoryId.value,
                          onSelect: (id) {
                            controller.selectCategory(id);
                            Get.back();
                          },
                          onAdd: () {
                            Get.back();
                            _addCategory();
                          },
                        )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// Expression line above the big amount; red with an error when ≤ 0.
class AmountDisplay extends GetView<AddTransactionController> {
  const AmountDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final value = controller.amount.value;
      final error = controller.amountError;
      final tone = error != null ? colorDanger : colorText;
      final expr = controller.expression.value;
      return Semantics(
        liveRegion: true,
        label:
            'Jumlah ${CurrencyService.to.money(value, signed: value < 0, maskable: false)}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              SizedBox(
                height: 20,
                child: Text(expr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySmall.muted),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${value < 0 ? CurrencyService.minus : ''}Rp ',
                        style: AppText.currencyPrefix
                            .copyWith(color: error != null ? tone : colorGrey)),
                    Text(
                        CurrencyService.to.digits(value.abs(), maskable: false),
                        style: AppText.amountXL.copyWith(color: tone)),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
                child: error == null
                    ? null
                    : Text(error,
                        style: AppText.caption.copyWith(color: colorDanger)),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // Cell height follows the text size so labels never clip (SC-006).
    final labelHeight = MediaQuery.textScalerOf(context).scale(16);
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
        mainAxisExtent: 58 + labelHeight,
      ),
      children: [
        for (var i = 0; i < categories.length; i++)
          _CategoryCell(
            category: categories[i],
            index: i,
            selected: categories[i]['id'] == selectedId,
            onTap: () => onSelect(categories[i]['id'] as int),
          ),
        _AddCell(onTap: onAdd),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final Map<String, dynamic> category;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCell({
    required this.category,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        themedColor(category['color_val'] as int?, fallbackIndex: index);
    final name = category['name'] as String;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? colorAccent : Colors.transparent,
                    width: 2),
              ),
              child: CategoryIcon.round(
                iconKey: category['icon_key'] as String?,
                iconPath: category['icon_path'] as String?,
                iconCode: category['icon_code'] as int?,
                color: color,
                diameter: 44,
              ),
            ),
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(
                    color: selected ? colorAccent : colorText,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _AddCell extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Kategori baru',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorDivider, width: 1.5),
                ),
                child: Icon(LucideIcons.plus, size: 20, color: colorGrey),
              ),
            ),
            const SizedBox(height: 4),
            Text('Baru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.muted),
          ],
        ),
      ),
    );
  }
}

/// Glass "tipis" sheet: account/date/note chips and the keypad.
class _KeypadSheet extends GetView<AddTransactionController> {
  const _KeypadSheet();

  @override
  Widget build(BuildContext context) {
    final tall = MediaQuery.sizeOf(context).height > 760;
    return GlassCard(
      level: GlassLevel.thin,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 12 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (!controller.isTransfer) ...[
                      _MetaChip(
                        icon: LucideIcons.wallet,
                        label: controller.selectedAccount?['name'] as String? ??
                            'Pilih rekening',
                        semantic: 'Pilih rekening',
                        onTap: () => _pickAccount(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _MetaChip(
                      icon: LucideIcons.calendar,
                      label: _dateLabel(controller.selectedDate.value),
                      semantic: 'Pilih tanggal',
                      onTap: () => controller.pickDate(context),
                    ),
                    const SizedBox(width: 8),
                    _MetaChip(
                      icon: LucideIcons.stickyNote,
                      label: controller.note.value.isEmpty
                          ? 'Catatan'
                          : controller.note.value,
                      semantic: 'Catatan',
                      onTap: _editNote,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          Obx(() => Keypad(
                onKey: controller.onKey,
                onSave: controller.save,
                saveEnabled: controller.canSave && !controller.isWorking.value,
                rowHeight: tall ? 56 : 52,
              )),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Hari ini';
    if (day == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return IdNames.shortDate(d);
  }

  void _pickAccount(BuildContext context) {
    showAccountPicker(
      accounts: controller.availableAccounts,
      selectedId: controller.selectedAccountId.value,
      onSelect: controller.selectAccount,
      onCreate: controller.createAccount,
    );
  }

  void _editNote() {
    final text = TextEditingController(text: controller.note.value);
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(Get.context!).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Catatan', style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 12),
              KField(
                controller: text,
                hint: 'Mis. Makan siang',
                autofocus: true,
                maxLength: 80,
                textInputAction: TextInputAction.done,
                onSubmitted: (v) {
                  controller.setNote(v);
                  Get.back();
                },
              ),
              const SizedBox(height: 12),
              KButton(
                label: 'Simpan catatan',
                onPressed: () {
                  controller.setNote(text.text);
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    ).whenComplete(text.dispose);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semantic;
  final VoidCallback onTap;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$semantic: $label',
      excludeSemantics: true,
      child: Material(
        color: colorSurface,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, maxWidth: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: colorGrey),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label.copyWith(color: colorText)),
                  ),
                  const SizedBox(width: 2),
                  Icon(LucideIcons.chevronDown, size: 14, color: colorGrey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing accounts with balances (shared by Catat/Transfer).
void showAccountPicker({
  required List<Map<String, dynamic>> accounts,
  required int? selectedId,
  required ValueChanged<int> onSelect,
  VoidCallback? onCreate,
  String title = 'Pilih rekening',
}) {
  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.title3.copyWith(color: colorText)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: ListGroup(
                  children: [
                    for (var i = 0; i < accounts.length; i++)
                      NavRow(
                        leading: CategoryIcon.round(
                          iconKey: accounts[i]['icon_key'] as String? ??
                              IconRegistry.accountTypeKey(
                                  accounts[i]['type'] as String? ?? ''),
                          color: themedColor(accounts[i]['color_val'] as int?,
                              fallbackIndex: i),
                        ),
                        title: accounts[i]['name'] as String,
                        subtitle: CurrencyService.to
                            .money(accounts[i]['balance'] as int? ?? 0),
                        showChevron: false,
                        trailing:
                            KRadio(selected: accounts[i]['id'] == selectedId),
                        onTap: () {
                          onSelect(accounts[i]['id'] as int);
                          Get.back();
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 12),
              KButton.text(
                label: 'Tambah rekening',
                icon: LucideIcons.plus,
                onPressed: () {
                  Get.back();
                  onCreate();
                },
              ),
            ],
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
