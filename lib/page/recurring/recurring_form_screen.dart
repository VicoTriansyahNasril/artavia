import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/recurring/recurring_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class RecurringFormScreen extends GetView<RecurringController> {
  const RecurringFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            controller.editingId == null ? 'Tambah Berulang' : 'Edit Berulang'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Obx(() => _Segmented<String>(
                values: const ['pengeluaran', 'pemasukan'],
                labels: const ['Pengeluaran', 'Pemasukan'],
                selected: controller.type.value,
                onChanged: controller.setType,
              )),
          const SizedBox(height: 16),
          TextField(
            controller: controller.amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            style: const TextStyle(
                color: colorText, fontSize: 20, fontWeight: FontWeight.w600),
            decoration:
                const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
          ),
          const SizedBox(height: 16),
          const _Label('Kategori'),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.categoriesForType.map((c) {
                  final id = c['id'] as int;
                  return ChoiceChip(
                    label: Text(c['name'] as String),
                    selected: controller.categoryId.value == id,
                    showCheckmark: false,
                    onSelected: (_) => controller.categoryId.value = id,
                  );
                }).toList(),
              )),
          const SizedBox(height: 16),
          const _Label('Rekening'),
          Obx(() => DropdownButtonFormField<int>(
                initialValue: controller.accountId.value,
                dropdownColor: colorSurface,
                items: controller.accounts
                    .map((a) => DropdownMenuItem(
                          value: a['id'] as int,
                          child: Text(a['name'] as String),
                        ))
                    .toList(),
                onChanged: (v) => controller.accountId.value = v,
              )),
          const SizedBox(height: 16),
          const _Label('Frekuensi'),
          Obx(() => _Segmented<RecurringFrequency>(
                values: RecurringFrequency.values,
                labels: RecurringFrequency.values.map((f) => f.label).toList(),
                selected: controller.frequency.value,
                onChanged: (f) => controller.frequency.value = f,
              )),
          const SizedBox(height: 16),
          Obx(() => ListTile(
                tileColor: colorSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.event_rounded),
                title: const Text('Mulai tanggal'),
                trailing: Text(IdNames.shortDate(controller.startDate.value),
                    style: const TextStyle(color: colorText)),
                onTap: () => controller.pickStartDate(context),
              )),
          const SizedBox(height: 16),
          TextField(
            controller: controller.noteController,
            style: const TextStyle(color: colorText),
            inputFormatters: [LengthLimitingTextInputFormatter(80)],
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Transaksi jatuh tempo dicatat otomatis saat aplikasi dibuka.',
            style: TextStyle(color: colorGrey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Obx(() => FilledButton(
                onPressed: controller.isWorking.value ? null : controller.save,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: const Text('Simpan'),
              )),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:
            Text(text, style: const TextStyle(color: colorGrey, fontSize: 12)),
      );
}

class _Segmented<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const _Segmented({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        backgroundColor: colorSurface,
        foregroundColor: colorGrey,
        selectedBackgroundColor: colorAccentDim,
        selectedForegroundColor: colorAccent,
        side: BorderSide.none,
      ),
      segments: [
        for (var i = 0; i < values.length; i++)
          ButtonSegment(value: values[i], label: Text(labels[i])),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
