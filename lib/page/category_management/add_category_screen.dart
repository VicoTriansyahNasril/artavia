import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/page/category_management/category_management_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Kategori baru / ubah (board): live preview, name ≤ 30, type, 12 colors,
/// icon groups + search over all 107 icons, sticky "Simpan kategori".
class AddCategoryScreen extends GetView<CategoryManagementController> {
  const AddCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final color = themedColor(c.colorVal.value);
      final version = c.formVersion.value;
      final label = c.name.value.trim();
      return AppScaffold(
        leading: ScaffoldLeading.close,
        title: c.isEditMode ? 'Ubah kategori' : 'Kategori baru',
        bottom: GlassCard(
          level: GlassLevel.regular,
          borderRadius: BorderRadius.zero,
          shadow: false,
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: KButton(
            label: 'Simpan kategori',
            onPressed: c.canSave && !c.isWorking.value ? c.saveCategory : null,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            GlassCard(
              child: Column(
                children: [
                  CategoryIcon.round(
                      iconKey: c.iconKey.value, color: color, diameter: 64),
                  const SizedBox(height: 10),
                  Text(label.isEmpty ? 'Nama kategori' : label,
                      textAlign: TextAlign.center,
                      style: AppText.title3.copyWith(
                          color: label.isEmpty ? colorGrey : colorText)),
                  Text(
                      c.formType.value == 'pemasukan'
                          ? 'Pemasukan'
                          : 'Pengeluaran',
                      style: AppText.caption.onGlass),
                ],
              ),
            ),
            const SizedBox(height: 16),
            KField(
              key: ValueKey('name$version'),
              label: 'Nama',
              hint: 'Mis. Kopi, Parkir, Freelance',
              initialValue: c.name.value,
              maxLength: CategoryManagementController.maxName,
              autofocus: !c.isEditMode,
              state:
                  c.nameError != null ? KFieldState.error : KFieldState.normal,
              helper: c.nameError ??
                  '${c.name.value.length}/${CategoryManagementController.maxName}',
              onChanged: (v) => c.name.value = v,
            ),
            const SizedBox(height: 12),
            KSegment<String>(
              height: 40,
              items: const {
                'pengeluaran': 'Pengeluaran',
                'pemasukan': 'Pemasukan',
              },
              value: c.formType.value,
              onChanged: (v) => c.formType.value = v,
            ),
            const SectionHeader(title: 'Warna'),
            PaletteColorPicker(
              value: c.colorVal.value,
              onChanged: (v) => c.colorVal.value = v,
            ),
            const SectionHeader(title: 'Ikon'),
            IconPicker(
              selected: c.iconKey.value,
              color: color,
              onSelect: (k) => c.iconKey.value = k,
            ),
            if (c.isEditMode) ...[
              const SizedBox(height: 20),
              KButton.danger(
                label: 'Hapus kategori',
                icon: LucideIcons.trash2,
                onPressed: () => c.deleteCategory({
                  'id': c.editingId.value,
                  'name': c.name.value,
                }),
              ),
            ],
          ],
        ),
      );
    });
  }
}
