import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/page/data_transfer/import_history_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Riwayat impor (board): Batalkan within 7 days; expired / cancelled
/// states.
class ImportHistoryScreen extends GetView<ImportHistoryController> {
  const ImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy, HH.mm', 'id_ID');
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Riwayat impor',
      body: Obx(() {
        final batches = controller.batches;
        if (batches.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.fileClock,
            title: 'Belum ada impor',
            body: 'File yang kamu impor akan muncul di sini.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            ListGroup(
              children: [
                for (final b in batches)
                  () {
                    final state = ImportHistoryController.stateOf(b);
                    final created = DateTime.parse(b['created_at'] as String);
                    final status = switch (state) {
                      BatchState.active =>
                        'Bisa dibatalkan ${ImportHistoryController.daysLeft(b)} hari lagi',
                      BatchState.expired =>
                        'Lewat 7 hari, tidak bisa dibatalkan',
                      BatchState.cancelled => 'Dibatalkan',
                    };
                    return NavRow(
                      icon: state == BatchState.cancelled
                          ? LucideIcons.fileX
                          : LucideIcons.fileCheck,
                      iconColor: state == BatchState.cancelled
                          ? colorGrey
                          : colorAccent,
                      title: b['file_name'] as String,
                      subtitle: '${fmt.format(created)} · '
                          '${b['transaction_count']} transaksi\n$status',
                      showChevron: false,
                      trailing: state == BatchState.active
                          ? KButton.tonal(
                              label: 'Batalkan',
                              onPressed: () => controller.cancel(b),
                            )
                          : null,
                    );
                  }(),
              ],
            ),
          ],
        );
      }),
    );
  }
}
