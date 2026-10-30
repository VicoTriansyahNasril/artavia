import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/backup_service.dart';
import 'package:artavia/page/backup/backup_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// "Cadangan ditemukan" (board, FR-033): shown once on a fresh install that
/// signs in to a Google account with backups.
class RestoreFoundScreen extends GetView<BackupController> {
  const RestoreFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.close,
      body: Obx(() {
        final c = controller;
        final e = c.selected.value;
        if (e == null) {
          return const EmptyState(
            icon: LucideIcons.cloudOff,
            title: 'Tidak ada cadangan',
            body: 'Belum ada cadangan di akun Google ini.',
          );
        }
        final fmt = DateFormat('d MMMM yyyy, HH.mm', 'id_ID');
        final others = c.service.history.length - 1;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: softFill(colorIncome),
                    borderRadius: BorderRadius.circular(22)),
                child:
                    Icon(LucideIcons.cloudCheck, size: 34, color: colorIncome),
              ),
            ),
            const SizedBox(height: 16),
            Text('Cadangan ditemukan',
                textAlign: TextAlign.center,
                style: AppText.title1.copyWith(color: colorText)),
            const SizedBox(height: 6),
            Text(
                'Pulihkan datamu dari Google Drive ${c.drive.email.value ?? ''}',
                textAlign: TextAlign.center,
                style: AppText.bodySmall.muted),
            const SizedBox(height: 12),
            ListGroup(
              dividerInset: 14,
              children: [
                _row('Asal', e.legacy ? 'Versi lama Artavia' : e.device),
                _row('Tanggal', e.legacy ? '—' : fmt.format(e.createdAt)),
                _row(
                    'Isi',
                    e.txCount > 0
                        ? '${e.txCount} transaksi · ${e.accountCount} rekening'
                        : '—'),
                _row('Ukuran', formatBytes(e.sizeBytes)),
              ],
            ),
            if (others > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: KButton.text(
                  label: 'Pilih cadangan lain ($others)',
                  expand: false,
                  onPressed: () => _pickOther(c),
                ),
              ),
            if (e.locked) ...[
              const SizedBox(height: 8),
              KField(
                key: ValueKey(e.id),
                label: 'Kata sandi cadangan',
                obscureText: true,
                state: c.passwordError.value
                    ? KFieldState.error
                    : KFieldState.normal,
                helper: c.passwordError.value
                    ? 'Kata sandi salah${e.hint == null ? '' : '. Petunjuk: ${e.hint}'}'
                    : (e.hint == null ? null : 'Petunjuk: ${e.hint}'),
                onChanged: (v) => c.password = v,
              ),
            ],
            const SizedBox(height: 20),
            KButton(
              label: c.restoring.value ? 'Memulihkan…' : 'Pulihkan data',
              icon: LucideIcons.history,
              onPressed: c.restoring.value
                  ? null
                  : () async {
                      if (await c.restore(e, confirm: false)) {
                        Get.until((r) => r.isFirst);
                      }
                    },
            ),
            const SizedBox(height: 8),
            KButton.text(label: 'Mulai dari awal', onPressed: Get.back),
          ],
        );
      }),
    );
  }

  static Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SizedBox(
                width: 80, child: Text(label, style: AppText.bodySmall.muted)),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: AppText.bodySmall.copyWith(color: colorText)),
            ),
          ],
        ),
      );

  void _pickOther(BackupController c) {
    final fmt = DateFormat('d MMM yyyy, HH.mm', 'id_ID');
    showSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pilih cadangan',
                  style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 12),
              ListGroup(
                children: [
                  for (final BackupEntry e in c.service.history)
                    NavRow(
                      icon: e.locked
                          ? LucideIcons.lockKeyhole
                          : LucideIcons.fileArchive,
                      title: e.legacy
                          ? 'Cadangan versi lama'
                          : fmt.format(e.createdAt),
                      subtitle: [
                        if (e.txCount > 0) '${e.txCount} transaksi',
                        formatBytes(e.sizeBytes),
                      ].join(' · '),
                      showChevron: false,
                      trailing: KRadio(selected: e.id == c.selected.value?.id),
                      onTap: () {
                        c.selected.value = e;
                        c.passwordError.value = false;
                        Get.back();
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
