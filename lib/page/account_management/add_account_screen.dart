import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class AddAccountScreen extends GetView<AccountManagementController> {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: Obx(() => Text(
              controller.isEditMode ? 'Edit Rekening' : 'Tambah Rekening',
            )),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            controller.resetForm();
            Get.back();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: controller.saveAccount,
              style: TextButton.styleFrom(
                backgroundColor: colorAccent,
                foregroundColor: colorBlack,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Simpan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Live Preview Card ────────────────────────────────────────
            _AccountPreviewCard(controller: controller),
            const SizedBox(height: 24),

            // ─── Tipe Rekening ────────────────────────────────────────────
            const _SectionLabel('Tipe Rekening'),
            const SizedBox(height: 10),
            _TypeSelectorGrid(controller: controller),
            const SizedBox(height: 24),

            // ─── Informasi Rekening ───────────────────────────────────────
            const _SectionLabel('Nama & Saldo'),
            const SizedBox(height: 10),
            _InfoCard(controller: controller),
            const SizedBox(height: 24),

            // ─── Mata Uang ────────────────────────────────────────────────
            const _SectionLabel('Mata Uang'),
            const SizedBox(height: 10),
            _CurrencyChips(controller: controller),
            const SizedBox(height: 24),

            // ─── Pilih Ikon ───────────────────────────────────────────────
            const _SectionLabel('Ikon Rekening'),
            const SizedBox(height: 10),
            _IconPickerGrid(controller: controller),
            const SizedBox(height: 24),

            // ─── Warna ────────────────────────────────────────────────────
            const _SectionLabel('Warna Ikon'),
            const SizedBox(height: 10),
            _ColorPicker(controller: controller),
            const SizedBox(height: 24),

            // ─── Toggle ───────────────────────────────────────────────────
            _ExcludeToggle(controller: controller),
            const SizedBox(height: 28),

            // ─── Save Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAccent,
                  foregroundColor: colorBlack,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Rekening',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preview Card ─────────────────────────────────────────────────────────────

class _AccountPreviewCard extends StatelessWidget {
  final AccountManagementController controller;
  const _AccountPreviewCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final color = Color(controller.selectedColorVal.value);
      final iconCode = controller.selectedIconCode.value;
      final iconPath = controller.selectedIconPath.value;
      final name = controller.accountName.value.isEmpty
          ? 'Nama Rekening'
          : controller.accountName.value;
      final balance = controller.balance.value;
      final currency = controller.currencyCode.value;
      final type = controller.typeValue.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: CategoryIcon(
                iconCode: iconCode,
                iconPath: iconPath,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: colorWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type,
                    style: const TextStyle(color: colorGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBalance(balance),
                  style: TextStyle(
                    color: balance < 0 ? colorExpense : colorWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  String _formatBalance(int amount) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    final formatted = abs.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$sign$formatted';
  }
}

// ─── Type Selector ────────────────────────────────────────────────────────────

class _TypeSelectorGrid extends StatelessWidget {
  final AccountManagementController controller;
  const _TypeSelectorGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.55,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: AccountManagementController.accountTypes.map((type) {
            final isSelected = controller.typeValue.value == type.label;
            final color = Color(type.defaultColorVal);
            return GestureDetector(
              onTap: () => controller.onTypeSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.13) : colorCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(type.icon,
                        color: isSelected ? color : colorGrey, size: 22),
                    const SizedBox(height: 5),
                    Text(
                      type.label,
                      style: TextStyle(
                        color: isSelected ? colorWhite : colorGrey,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ));
  }
}

// ─── Info Card (Name + Balance) ────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final AccountManagementController controller;
  const _InfoCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Name field
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 76,
                  child: Text('Nama',
                      style: TextStyle(color: colorGrey, fontSize: 14)),
                ),
                Expanded(
                  child: TextField(
                    autofocus: false,
                    controller: controller.nameController,
                    onChanged: (v) => controller.accountName.value = v,
                    style: const TextStyle(color: colorWhite, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'cth: BCA, GoPay, Dompet',
                      hintStyle: TextStyle(color: colorGrey, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: colorDivider, height: 1, indent: 16),
          // Balance field
          Obx(() => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 76,
                      child: Text('Saldo Awal',
                          style: TextStyle(color: colorGrey, fontSize: 14)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller.balanceController,
                        onChanged: (v) {
                          controller.balance.value =
                              int.tryParse(v.replaceAll(
                                      RegExp(r'[^0-9\-]'), '')) ??
                                  0;
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(12),
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^-?\d*')),
                        ],
                        style: const TextStyle(color: colorWhite, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle:
                              const TextStyle(color: colorGrey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          prefixText:
                              '${controller.currencyCode.value} ',
                          prefixStyle:
                              const TextStyle(color: colorGrey, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Currency Chips ───────────────────────────────────────────────────────────

class _CurrencyChips extends StatelessWidget {
  final AccountManagementController controller;
  const _CurrencyChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AccountManagementController.supportedCurrencies
                .map((c) {
              final isSelected = controller.currencyCode.value == c['code'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      controller.onCurrencySelected(c['code']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorAccent.withValues(alpha: 0.15)
                          : colorCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? colorAccent
                            : colorDivider,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c['symbol']!,
                          style: TextStyle(
                            color: isSelected ? colorAccent : colorWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['code']!,
                          style: TextStyle(
                            color: isSelected ? colorAccent : colorGrey,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ));
  }
}

// ─── Icon Picker Grid ─────────────────────────────────────────────────────────

class _IconPickerGrid extends StatelessWidget {
  final AccountManagementController controller;
  const _IconPickerGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedColor = Color(controller.selectedColorVal.value);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: AccountManagementController.keuanganIcons.map((iconPath) {
            final isSelected = controller.selectedIconPath.value == iconPath;
            return GestureDetector(
              onTap: () => controller.onIconSelected(iconPath),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? selectedColor.withValues(alpha: 0.18)
                      : colorSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? selectedColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  iconPath,
                  color: isSelected ? selectedColor : colorGrey,
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

// ─── Color Picker ─────────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final AccountManagementController controller;
  const _ColorPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: controller.presetColors.map((color) {
              final isSelected =
                  controller.selectedColorVal.value == color.toARGB32();
              return GestureDetector(
                onTap: () => controller.onColorSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colorWhite : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1)
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          )),
    );
  }
}

// ─── Exclude Toggle ───────────────────────────────────────────────────────────

class _ExcludeToggle extends StatelessWidget {
  final AccountManagementController controller;
  const _ExcludeToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: colorGrey, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kecualikan dari Total',
                  style: TextStyle(
                    color: colorWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Saldo tidak dihitung dalam kekayaan bersih',
                  style: TextStyle(color: colorGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          Obx(() => Switch(
                value: controller.excludeFromTotal.value,
                onChanged: (val) => controller.excludeFromTotal.value = val,
              )),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: colorGrey,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}
