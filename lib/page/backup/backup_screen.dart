import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/backup_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/page/backup/backup_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Cadangan Google Drive (board): belum terhubung / terhubung / sedang
/// mencadangkan.
class BackupScreen extends GetView<BackupController> {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Cadangan Google Drive',
      body: Obx(() {
        final c = controller;
        if (!c.drive.isConnected.value) return _Disconnected(c: c);
        // Children are plain widgets: read what they show here.
        c.service.history.length;
        c.service.progress.value;
        c.drive.email.value;
        for (final k in [
          SettingsService.keyBackupAuto,
          SettingsService.keyBackupWifiOnly,
          SettingsService.keyBackupLocked,
          SettingsService.keyBackupHint,
          SettingsService.keyLastBackupAt,
        ]) {
          c.settings.get(k);
        }
        return Stack(
          children: [
            _Connected(c: c),
            if (c.service.phase.value == BackupPhase.running) _Running(c: c),
            if (c.restoring.value)
              const ColoredBox(
                color: colorScrim,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }
}

class _Disconnected extends StatelessWidget {
  final BackupController c;
  const _Disconnected({required this.c});

  @override
  Widget build(BuildContext context) {
    Widget benefit(IconData icon, String title, String body) => NavRow(
          icon: icon,
          title: title,
          subtitle: body,
          showChevron: false,
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: colorAccentDim, borderRadius: BorderRadius.circular(22)),
            child: Icon(LucideIcons.cloudUpload, size: 34, color: colorAccent),
          ),
        ),
        const SizedBox(height: 16),
        Text('Simpan data di Google Drive',
            textAlign: TextAlign.center,
            style: AppText.title1.copyWith(color: colorText)),
        const SizedBox(height: 6),
        Text('Kalau HP hilang atau ganti HP, datamu bisa dipulihkan.',
            textAlign: TextAlign.center, style: AppText.bodySmall.muted),
        const SizedBox(height: 8),
        ListGroup(
          children: [
            benefit(LucideIcons.calendarClock, 'Otomatis tiap hari',
                'Berjalan saat aplikasi dibuka, paling banyak sekali sehari'),
            benefit(LucideIcons.lockKeyhole, 'Bisa dikunci kata sandi',
                'Isi cadangan dienkripsi AES-256 sebelum diunggah'),
            benefit(LucideIcons.history, '5 cadangan terakhir',
                'Pulihkan versi mana pun kapan saja'),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: colorAccentDim, borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: colorAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Artavia hanya bisa membuka folder khususnya sendiri. '
                    'File lain di Google Drive-mu tidak bisa dilihat.',
                    style: AppText.caption.copyWith(color: colorAccent)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Obx(() => KButton(
              label: c.drive.isConnecting.value
                  ? 'Menghubungkan…'
                  : 'Hubungkan Google Drive',
              icon: LucideIcons.link,
              onPressed: c.drive.isConnecting.value ? null : c.connect,
            )),
        const SizedBox(height: 8),
        KButton.text(label: 'Nanti saja', onPressed: Get.back),
      ],
    );
  }
}

/// Google profile photo; the name's initial on an accent circle when there
/// is no photo or it fails to load (offline).
class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  const _Avatar({this.photoUrl, this.name});

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final initial = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colorAccentDim, shape: BoxShape.circle),
      child: name == null || name!.trim().isEmpty
          ? Icon(LucideIcons.circleUser, size: 22, color: colorAccent)
          : Text(name!.trim()[0].toUpperCase(),
              style: AppText.title3.copyWith(color: colorAccent)),
    );
    if (photoUrl == null) return initial;
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initial,
      ),
    );
  }
}

class _Connected extends StatelessWidget {
  final BackupController c;
  const _Connected({required this.c});

  @override
  Widget build(BuildContext context) {
    final s = c.settings;
    final last = s.lastBackupAt;
    final history = c.service.history;
    final fmt = DateFormat('d MMM yyyy, HH.mm', 'id_ID');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        ListGroup(
          children: [
            NavRow(
              leading: _Avatar(
                photoUrl: c.drive.photoUrl.value,
                name: c.drive.displayName.value ?? c.drive.email.value,
              ),
              title: c.drive.displayName.value ??
                  c.drive.email.value ??
                  'Akun Google',
              subtitle: c.drive.displayName.value == null
                  ? 'Terhubung'
                  : '${c.drive.email.value ?? ''} · Terhubung',
              showChevron: false,
              trailing:
                  KButton.tonal(label: 'Ganti', onPressed: c.switchAccount),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cadangan terakhir', style: AppText.caption.onGlass),
              const SizedBox(height: 4),
              Text(last == null ? 'Belum ada' : fmt.format(last),
                  style: AppText.title2.copyWith(color: colorText)),
              if (last != null)
                Text(
                    '${s.lastBackupTx} transaksi · ${formatBytes(s.lastBackupBytes)}'
                    '${c.service.isLocked ? ' · dikunci' : ''}',
                    style: AppText.caption.onGlass),
              const SizedBox(height: 14),
              const KButton(
                label: 'Cadangkan sekarang',
                icon: LucideIcons.cloudUpload,
                onPressed: runBackup,
              ),
            ],
          ),
        ),
        ListGroup(
          title: 'Pengaturan',
          children: [
            _switch(
              LucideIcons.calendarClock,
              'Cadangan otomatis harian',
              'Berjalan saat aplikasi dibuka',
              s.backupAuto,
              c.setAuto,
            ),
            _switch(LucideIcons.wifi, 'Hanya lewat Wi-Fi', null,
                s.backupWifiOnly, c.setWifiOnly),
            _switch(
              LucideIcons.lockKeyhole,
              'Kunci dengan kata sandi',
              c.service.isLocked
                  ? 'Petunjuk: ${s.backupHint ?? '—'}'
                  : 'Dienkripsi sebelum diunggah',
              c.service.isLocked,
              (on) => on ? _passwordSheet(c) : c.removePassword(),
            ),
          ],
        ),
        ListGroup(
          title: 'Riwayat cadangan',
          children: [
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Belum ada cadangan di Google Drive',
                    style: AppText.bodySmall.muted),
              ),
            for (final e in history)
              NavRow(
                icon: e.locked
                    ? LucideIcons.lockKeyhole
                    : LucideIcons.fileArchive,
                title:
                    e.legacy ? 'Cadangan versi lama' : fmt.format(e.createdAt),
                subtitle: [
                  if (e.txCount > 0) '${e.txCount} transaksi',
                  formatBytes(e.sizeBytes),
                  e.device,
                ].join(' · '),
                showChevron: false,
                trailing: KButton.tonal(
                  label: 'Pulihkan',
                  onPressed: () => _restore(c, e),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        KButton.danger(
          label: 'Putuskan Google Drive',
          icon: LucideIcons.unlink,
          onPressed: c.disconnect,
        ),
      ],
    );
  }

  static Widget _switch(IconData icon, String title, String? subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return NavRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      trailing:
          KSwitch(value: value, onChanged: onChanged, semanticLabel: title),
      onTap: () => onChanged(!value),
    );
  }

  void _restore(BackupController c, BackupEntry e) {
    if (!e.locked) {
      c.password = '';
      c.restore(e);
      return;
    }
    passwordPrompt(c, e);
  }

  void _passwordSheet(BackupController c) {
    var password = '', confirm = '', hint = '';
    final valid = false.obs;
    void check() => valid.value = password.length >= 8 && password == confirm;
    showSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, 16 + MediaQuery.viewInsetsOf(Get.context!).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kunci cadangan',
                  style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 4),
              Text(
                  'Kata sandi tidak disimpan dan tidak bisa direset. Tanpa '
                  'kata sandi, cadangan tidak bisa dibuka.',
                  style: AppText.caption.muted),
              const SizedBox(height: 12),
              KField(
                label: 'Kata sandi (min. 8 karakter)',
                obscureText: true,
                autofocus: true,
                onChanged: (v) {
                  password = v;
                  check();
                },
              ),
              const SizedBox(height: 10),
              KField(
                label: 'Ulangi kata sandi',
                obscureText: true,
                onChanged: (v) {
                  confirm = v;
                  check();
                },
              ),
              const SizedBox(height: 10),
              KField(
                label: 'Petunjuk (opsional)',
                hint: 'Mis. nama kucing pertama',
                maxLength: 60,
                helper: 'Petunjuk terlihat oleh siapa pun yang memegang file.',
                onChanged: (v) => hint = v,
              ),
              const SizedBox(height: 16),
              Obx(() => KButton(
                    label: 'Aktifkan kata sandi',
                    onPressed: valid.value
                        ? () {
                            Get.back();
                            c.setPassword(password, hint);
                          }
                        : null,
                  )),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// Password sheet for restoring a locked backup; red ring + hint when wrong.
void passwordPrompt(BackupController c, BackupEntry e) {
  c.passwordError.value = false;
  c.password = '';
  showSheet(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 16 + MediaQuery.viewInsetsOf(Get.context!).bottom),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cadangan ini dikunci',
                    style: AppText.title3.copyWith(color: colorText)),
                const SizedBox(height: 12),
                KField(
                  label: 'Kata sandi cadangan',
                  obscureText: true,
                  autofocus: true,
                  state: c.passwordError.value
                      ? KFieldState.error
                      : KFieldState.normal,
                  helper: c.passwordError.value
                      ? 'Kata sandi salah${e.hint == null ? '' : '. Petunjuk: ${e.hint}'}'
                      : null,
                  onChanged: (v) => c.password = v,
                ),
                const SizedBox(height: 16),
                KButton(
                  label: c.restoring.value ? 'Memulihkan…' : 'Pulihkan data',
                  onPressed: c.restoring.value
                      ? null
                      : () async {
                          if (await c.restore(e)) Get.back();
                        },
                ),
              ],
            )),
      ),
    ),
    isScrollControlled: true,
  );
}

class _Running extends StatelessWidget {
  final BackupController c;
  const _Running({required this.c});

  @override
  Widget build(BuildContext context) {
    final pct = (c.service.progress.value * 100).round();
    return ColoredBox(
      color: colorScrim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            level: GlassLevel.thick,
            padding: const EdgeInsets.all(20),
            child: Semantics(
              liveRegion: true,
              label: 'Mencadangkan $pct persen',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Mencadangkan…',
                      style: AppText.title3.copyWith(color: colorText)),
                  const SizedBox(height: 4),
                  Text('Jangan tutup aplikasi sampai selesai.',
                      style: AppText.caption.onGlass),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: KProgress(value: c.service.progress.value)),
                      const SizedBox(width: 12),
                      Text('$pct%',
                          style: AppText.label.copyWith(color: colorText)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  KButton.text(label: 'Batalkan', onPressed: c.service.cancel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
