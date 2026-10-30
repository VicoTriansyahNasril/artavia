import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/add_transaction/add_transaction_controller.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/transfer/transfer_section.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Catat (board "Catat transaksi"): segment, date + amount + expression,
/// category grid (or the transfer section), and a glass sheet with the
/// account, an inline note box and the keypad.
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

/// Amount + the full category grid for Pengeluaran / Pemasukan, in the
/// order set in Kelola Kategori ("Atur urutan"). Date and amount stay
/// pinned above the scrolling grid so what is typed is always in view.
class _EntryBody extends StatefulWidget {
  const _EntryBody();

  @override
  State<_EntryBody> createState() => _EntryBodyState();
}

class _EntryBodyState extends State<_EntryBody> {
  /// Below this body height pinning would leave the grid under one row
  /// (e.g. 360×640 with the keypad up), so everything scrolls together and
  /// typing scrolls back up to the amount instead.
  static const _pinMinHeight = 280.0;

  final AddTransactionController controller = Get.find();
  final _scroll = ScrollController();
  late final Worker _typing;
  bool _pinned = true;

  @override
  void initState() {
    super.initState();
    _typing = everAll([controller.amount, controller.expression], (_) {
      if (!_pinned) _scrollToAmount();
    });
  }

  @override
  void dispose() {
    _typing.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToAmount() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _select(int id) {
    final first = controller.selectedCategoryId.value == null;
    controller.selectCategory(id);
    // The keypad appears now; bring the amount into view to type it.
    if (first && !_pinned) _scrollToAmount();
  }

  @override
  Widget build(BuildContext context) {
    final amount = <Widget>[
      // Outside AmountDisplay's merged semantics so it stays a button.
      const Center(child: CatatDateChip()),
      const AmountDisplay(),
    ];
    final grid = <Widget>[
      const SizedBox(height: 8),
      SectionHeader(
        title: 'Kategori',
        action: KButton.text(
          label: 'Atur urutan',
          compact: true,
          expand: false,
          onPressed: _arrange,
        ),
      ),
      Obx(() => _CategoryGrid(
            categories: controller.categories,
            selectedId: controller.selectedCategoryId.value,
            onSelect: _select,
            onAdd: _addCategory,
          )),
    ];
    return LayoutBuilder(builder: (context, box) {
      _pinned = box.maxHeight >= _pinMinHeight;
      if (!_pinned) {
        return ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [...amount, ...grid],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(children: amount),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: grid,
            ),
          ),
        ],
      );
    });
  }

  String get _type =>
      controller.currentTab.value == 'Pemasukan' ? 'pemasukan' : 'pengeluaran';

  Future<void> _arrange() async {
    await Get.toNamed(categoryManagementRoute, arguments: {'type': _type});
    await controller.reloadCategories();
  }

  Future<void> _addCategory() async {
    await Get.toNamed(addCategoryRoute, arguments: {'type': _type});
    await controller.reloadCategories();
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

/// Transaction date as a chip ("Hari ini", "Kemarin", "12 Okt"); opens the
/// date picker. Sits with the amount on every Catat tab.
class CatatDateChip extends GetView<AddTransactionController> {
  const CatatDateChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => _MetaChip(
          icon: LucideIcons.calendar,
          label: _dateLabel(controller.selectedDate.value),
          semantic: 'Pilih tanggal',
          onTap: () => controller.pickDate(context),
        ));
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Hari ini';
    if (day == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return IdNames.shortDate(d);
  }
}

/// Glass "tipis" sheet: account chip + inline note box, then the keypad —
/// once a category is picked. The keypad steps aside while the note is
/// focused so it never stacks under the system keyboard.
class _KeypadSheet extends StatefulWidget {
  const _KeypadSheet();

  @override
  State<_KeypadSheet> createState() => _KeypadSheetState();
}

class _KeypadSheetState extends State<_KeypadSheet> {
  final AddTransactionController controller = Get.find();
  late final _note = TextEditingController(text: controller.note.value);
  final _noteFocus = FocusNode();
  late final Worker _noteSync;

  @override
  void initState() {
    super.initState();
    _noteFocus.addListener(() => setState(() {}));
    // The note arrives after this sheet is built when editing a transaction.
    _noteSync = ever<String>(controller.note, (v) {
      if (!_noteFocus.hasFocus && v != _note.text.trim()) _note.text = v;
    });
  }

  @override
  void dispose() {
    _noteSync.dispose();
    _noteFocus.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tall = MediaQuery.sizeOf(context).height > 760;
    final typing = _noteFocus.hasFocus;
    return GlassCard(
      level: GlassLevel.thin,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, typing ? 10 : 12 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Row(
                children: [
                  if (!controller.isTransfer) ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .42),
                      child: _MetaChip(
                        icon: LucideIcons.wallet,
                        label:
                            controller.selectedAccount?['name'] as String? ??
                                'Pilih rekening',
                        semantic: 'Pilih rekening',
                        onTap: _pickAccount,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _NoteBox(
                      controller: _note,
                      focusNode: _noteFocus,
                      onChanged: controller.setNote,
                    ),
                  ),
                ],
              )),
          if (!typing)
            Obx(() => AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: controller.showKeypad
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Keypad(
                            onKey: controller.onKey,
                            onSave: controller.save,
                            saveEnabled: controller.canSave &&
                                !controller.isWorking.value,
                            rowHeight: tall ? 56 : 52,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text('Pilih kategori untuk mengisi jumlah',
                              textAlign: TextAlign.center,
                              style: AppText.caption.muted),
                        ),
                )),
        ],
      ),
    );
  }

  void _pickAccount() {
    _noteFocus.unfocus();
    showAccountPicker(
      accounts: controller.availableAccounts,
      selectedId: controller.selectedAccountId.value,
      onSelect: controller.selectAccount,
      onCreate: controller.createAccount,
    );
  }
}

/// Inline note box, styled like the chips beside it (36 h, stadium,
/// surface fill).
class _NoteBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _NoteBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: colorSurface,
        shape: StadiumBorder(
          side: focusNode.hasFocus
              ? BorderSide(color: colorAccent, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.stickyNote, size: 16, color: colorGrey),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onTapOutside: (_) => focusNode.unfocus(),
              maxLength: 80,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.label.copyWith(color: colorText),
              cursorColor: colorAccent,
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)',
                hintStyle: AppText.label.copyWith(color: colorGrey),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
        ],
      ),
    );
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
  showSheet(
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
