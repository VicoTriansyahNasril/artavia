import 'package:flutter/material.dart';
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
        elevation: 0,
        title: Obx(() => Text(
              controller.isEditMode ? 'Edit Rekening' : 'Tambah Rekening',
              style: const TextStyle(
                  color: colorWhite, fontSize: 18, fontWeight: FontWeight.bold),
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () {
            controller.resetForm();
            Get.back();
          },
        ),
        actions: [
          TextButton(
            onPressed: controller.saveAccount,
            child: const Text('Simpan',
                style: TextStyle(
                    color: colorAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Tipe Rekening (Visual selector) ─────────────────────────
            const _SectionLabel('Tipe Rekening'),
            const SizedBox(height: 10),
            _buildTypeSelector(),

            const SizedBox(height: 20),

            // ─── Nama & Saldo ─────────────────────────────────────────────
            const _SectionLabel('Informasi Rekening'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colorCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildNameField(),
                  const Divider(color: colorBackground, height: 1, indent: 16),
                  _buildBalanceField(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Warna ───────────────────────────────────────────────────
            const _SectionLabel('Warna Ikon'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildColorPicker(),
            ),

            const SizedBox(height: 20),

            // ─── Exclude toggle ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: colorCard,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kecualikan dari total',
                            style: TextStyle(
                                color: colorWhite, fontSize: 14)),
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
                        onChanged: (val) =>
                            controller.excludeFromTotal.value = val,
                        activeColor: colorAccent,
                      )),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ─── Save Button (bottom) ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAccent,
                  foregroundColor: colorBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Simpan Rekening',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Type selector grid ──────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    return Obx(() {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: AccountManagementController.accountTypes.map((type) {
          final isSelected = controller.typeValue.value == type.label;
          final color = Color(type.defaultColorVal);
          return GestureDetector(
            onTap: () => controller.onTypeSelected(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : colorCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon,
                      color: isSelected ? color : colorGrey,
                      size: 22),
                  const SizedBox(height: 5),
                  Text(
                    type.label,
                    style: TextStyle(
                      color: isSelected ? colorWhite : colorGrey,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
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
      );
    });
  }

  // ─── Name field ──────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text('Nama',
                style: TextStyle(color: colorGrey, fontSize: 14)),
          ),
          Expanded(
            child: TextField(
              autofocus: false,
              controller: TextEditingController(text: controller.accountName.value)
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.accountName.value.length)),
              onChanged: (v) => controller.accountName.value = v,
              style: const TextStyle(color: colorWhite),
              decoration: const InputDecoration(
                hintText: 'cth: BCA, GoPay, CASH...',
                hintStyle: TextStyle(color: colorGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Balance field ───────────────────────────────────────────────────────

  Widget _buildBalanceField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text('Saldo Awal',
                style: TextStyle(color: colorGrey, fontSize: 14)),
          ),
          Expanded(
            child: Obx(() => TextField(
                  key: ValueKey(controller.editingId.value),
                  controller: TextEditingController(
                    text: controller.balance.value == 0
                        ? ''
                        : controller.balance.value.toString(),
                  ),
                  onChanged: (v) {
                    controller.balance.value =
                        int.tryParse(v.replaceAll(RegExp(r'[^0-9\-]'), '')) ??
                            0;
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true),
                  style: const TextStyle(color: colorWhite),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: colorGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(color: colorGrey),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  // ─── Color picker ────────────────────────────────────────────────────────

  Widget _buildColorPicker() {
    return Obx(() {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: controller.presetColors.map((color) {
          final isSelected =
              controller.selectedColorVal.value == color.value;
          return GestureDetector(
            onTap: () =>
                controller.selectedColorVal.value = color.value,
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
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          );
        }).toList(),
      );
    });
  }
}

// Helper label widget
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
