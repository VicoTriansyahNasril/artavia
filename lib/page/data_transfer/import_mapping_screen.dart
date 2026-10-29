import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/import_service.dart';
import 'package:artavia/page/data_transfer/import_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Impor step 2 (board): file card, one row per field with its column and
/// a sample, detected date format / thousand separator.
class ImportMappingScreen extends GetView<ImportController> {
  const ImportMappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller;
      final f = c.file.value;
      if (f == null) return const SizedBox.shrink();
      final missing = c.missing;
      return AppScaffold(
        leading: ScaffoldLeading.back,
        title: 'Cocokkan kolom',
        bottom: GlassCard(
          level: GlassLevel.regular,
          borderRadius: BorderRadius.zero,
          shadow: false,
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (missing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Pilih kolom untuk: ${missing.join(', ')}',
                      style: AppText.caption.copyWith(color: colorDanger)),
                ),
              KButton(
                label: c.isWorking.value ? 'Memeriksa…' : 'Lanjut tinjau',
                onPressed:
                    missing.isEmpty && !c.isWorking.value ? c.review : null,
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const StepHeader(step: 2, label: 'Cocokkan kolom'),
            const SizedBox(height: 12),
            ListGroup(
              children: [
                NavRow(
                  icon: f.name.toLowerCase().endsWith('.xlsx')
                      ? LucideIcons.fileSpreadsheet
                      : LucideIcons.fileText,
                  title: f.name,
                  subtitle:
                      '${f.rows.length} baris · ${f.headers.length} kolom',
                  showChevron: false,
                ),
              ],
            ),
            ListGroup(
              title: 'Kolom',
              children: [
                for (final field in ImportField.values)
                  _FieldRow(c: c, field: field, headers: f.headers),
              ],
            ),
            ListGroup(
              title: 'Terdeteksi',
              children: [
                NavRow(
                  icon: LucideIcons.calendar,
                  title: 'Format tanggal',
                  trailingText: c.order.value.example,
                  onTap: () => _pick<DateOrder>(
                    'Format tanggal',
                    DateOrder.values,
                    (o) => o.example,
                    c.order.value,
                    (o) => c.order.value = o,
                  ),
                ),
                NavRow(
                  icon: LucideIcons.hash,
                  title: 'Pemisah ribuan',
                  trailingText:
                      c.thousandSep.value == '.' ? '1.000.000' : '1,000,000',
                  onTap: () => _pick<String>(
                    'Pemisah ribuan',
                    const ['.', ','],
                    (s) => s == '.' ? '1.000.000 (titik)' : '1,000,000 (koma)',
                    c.thousandSep.value,
                    (s) => c.thousandSep.value = s,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  static void _pick<T>(String title, List<T> options, String Function(T) label,
      T selected, ValueChanged<T> onSelected) {
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
              ListGroup(
                dividerInset: 14,
                children: [
                  for (final o in options)
                    NavRow(
                      title: label(o),
                      showChevron: false,
                      trailing: KRadio(selected: o == selected),
                      onTap: () {
                        Get.back();
                        onSelected(o);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _FieldRow extends StatelessWidget {
  final ImportController c;
  final ImportField field;
  final List<String> headers;

  const _FieldRow(
      {required this.c, required this.field, required this.headers});

  @override
  Widget build(BuildContext context) {
    final col = c.mapping[field];
    final sample = c.samples(field).firstOrNull;
    final ok = col != null;
    return NavRow(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: softFill(
              ok ? colorIncome : (field.required ? colorDanger : colorGrey)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
            ok
                ? LucideIcons.check
                : (field.required
                    ? LucideIcons.circleAlert
                    : LucideIcons.minus),
            size: 18,
            color:
                ok ? colorIncome : (field.required ? colorDanger : colorGrey)),
      ),
      title: field.required ? '${field.label} · wajib' : field.label,
      subtitle: ok
          ? '${headers[col]}${sample == null ? '' : ' · mis. $sample'}'
          : 'Tidak dipakai',
      onTap: () => _choose(),
    );
  }

  void _choose() {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kolom untuk ${field.label}',
                  style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: ListGroup(
                    dividerInset: 14,
                    children: [
                      if (!field.required)
                        NavRow(
                          title: 'Tidak dipakai',
                          showChevron: false,
                          trailing: KRadio(selected: c.mapping[field] == null),
                          onTap: () {
                            Get.back();
                            c.setColumn(field, null);
                          },
                        ),
                      for (var i = 0; i < headers.length; i++)
                        NavRow(
                          title: headers[i].isEmpty
                              ? 'Kolom ${i + 1}'
                              : headers[i],
                          showChevron: false,
                          trailing: KRadio(selected: c.mapping[field] == i),
                          onTap: () {
                            Get.back();
                            c.setColumn(field, i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
