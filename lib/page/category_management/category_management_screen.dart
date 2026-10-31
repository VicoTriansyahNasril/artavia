import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/page/category_management/category_management_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Kategori (board): type segment with counts, "Tambah kategori", drag
/// handles to reorder (the order Catat shows), "Urutkan otomatis",
/// archived link.
class CategoryManagementScreen extends GetView<CategoryManagementController> {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Kategori',
      body: Obx(() {
        final c = controller;
        final list = c.visible;
        c.counts.length;
        c.budgets.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: KSegment<String>(
                items: {
                  'pengeluaran': 'Pengeluaran · ${c.expense.length}',
                  'pemasukan': 'Pemasukan · ${c.income.length}',
                },
                value: c.currentType.value,
                onChanged: c.changeType,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KButton.tonal(
                label: 'Tambah kategori',
                icon: LucideIcons.plus,
                expand: true,
                onPressed: c.openNew,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                buildDefaultDragHandles: false,
                header: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Urutan ini dipakai di Catat. Tahan ⠿ lalu geser '
                          'untuk memindah.',
                          style: AppText.caption.muted),
                      KButton.text(
                        label: 'Urutkan otomatis',
                        icon: LucideIcons.arrowDownWideNarrow,
                        compact: true,
                        expand: false,
                        onPressed: list.length < 2 ? null : c.sortByUsage,
                      ),
                    ],
                  ),
                ),
                itemCount: list.length,
                onReorderItem: c.reorder,
                proxyDecorator: (child, _, __) => Material(
                  color: Colors.transparent,
                  elevation: 0,
                  child: child,
                ),
                footer: c.archived.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: KButton.text(
                            label: '${c.archived.length} kategori diarsipkan',
                            icon: LucideIcons.archive,
                            compact: true,
                            expand: false,
                            onPressed: _showArchived,
                          ),
                        ),
                      ),
                itemBuilder: (context, i) => _CategoryRow(
                  key: ValueKey(list[i]['id']),
                  category: list[i],
                  index: i,
                  first: i == 0,
                  last: i == list.length - 1,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showArchived() {
    final c = controller;
    showSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Kategori diarsipkan',
                      style: AppText.title3.copyWith(color: colorText)),
                  const SizedBox(height: 12),
                  ListGroup(
                    children: [
                      for (final cat in c.archived)
                        NavRow(
                          leading: CategoryIcon.round(
                            iconKey: cat['icon_key'] as String?,
                            iconPath: cat['icon_path'] as String?,
                            color: themedColor(cat['color_val'] as int?),
                          ),
                          title: cat['name'] as String,
                          subtitle: cat['type'] == 'pemasukan'
                              ? 'Pemasukan'
                              : 'Pengeluaran',
                          showChevron: false,
                          trailing: KButton.tonal(
                            label: 'Pulihkan',
                            onPressed: () => c.setArchived(cat, false),
                          ),
                        ),
                    ],
                  ),
                ],
              )),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _CategoryRow extends GetView<CategoryManagementController> {
  final Map<String, dynamic> category;
  final int index;
  final bool first;
  final bool last;

  const _CategoryRow({
    super.key,
    required this.category,
    required this.index,
    required this.first,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final id = category['id'] as int;
    final count = controller.counts[id] ?? 0;
    final budget = controller.budgets[id];
    final subtitle = [
      '$count transaksi',
      if (budget != null) 'Anggaran $budget',
    ].join(' · ');
    final radius = BorderRadius.vertical(
      top: Radius.circular(first ? 16 : 0),
      bottom: Radius.circular(last ? 16 : 0),
    );
    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: radius,
      ),
      child: Column(
        children: [
          NavRow(
            leading: CategoryIcon.round(
              iconKey: category['icon_key'] as String?,
              iconPath: category['icon_path'] as String?,
              iconCode: category['icon_code'] as int?,
              color: themedColor(category['color_val'] as int?,
                  fallbackIndex: index),
            ),
            title: category['name'] as String,
            subtitle: subtitle,
            showChevron: false,
            trailing: ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: 'Ubah urutan ${category['name']}',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(LucideIcons.gripVertical,
                      size: 20, color: colorGrey),
                ),
              ),
            ),
            onTap: () => controller.openEdit(category),
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.only(left: 68),
              child: Divider(height: 1, color: colorDivider),
            ),
        ],
      ),
    );
  }
}
