import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/core/services/settings_service.dart';
import 'package:artavia/core/services/theme_service.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/settings/settings_controller.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Standalone route around [SettingsView].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Pengaturan',
      body: SettingsView(),
    );
  }
}

/// Pengaturan tab (board "Pengaturan").
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadStats,
      backgroundColor: colorCard,
      color: colorAccent,
      child: Obx(() {
        final c = controller;
        final s = c.settings;
        final t = c.theme;
        // Reactive reads for the plain rows below.
        s.get(SettingsService.keyHaptics);
        s.get(SettingsService.keyLastBackupAt);
        s.get(SettingsService.keyBackupNudgeHidden);
        t.pref.value;
        t.textScale.value;
        t.reduceTransparency.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            const _DataStatusCard(),
            ListGroup(
              title: 'Keuangan',
              children: [
                NavRow(
                  icon: LucideIcons.wallet,
                  title: 'Rekening',
                  trailingText: '${c.accountCount.value}',
                  onTap: () => Get.toNamed(accountManagementRoute),
                ),
                NavRow(
                  icon: LucideIcons.shapes,
                  title: 'Kategori',
                  trailingText: '${c.categoryCount.value}',
                  onTap: () => Get.toNamed(categoryManagementRoute),
                ),
                NavRow(
                  icon: LucideIcons.target,
                  title: 'Anggaran',
                  onTap: () => Get.toNamed(budgetRoute),
                ),
                NavRow(
                  icon: LucideIcons.repeat,
                  title: 'Transaksi berulang',
                  trailingText: '${c.recurringCount.value}',
                  onTap: () => Get.toNamed(recurringRoute),
                ),
              ],
            ),
            ListGroup(
              title: 'Tampilan',
              children: [
                NavRow(
                  icon: LucideIcons.sunMoon,
                  title: 'Tema',
                  trailingText: t.themeLabel,
                  onTap: _pickTheme,
                ),
                NavRow(
                  icon: LucideIcons.aLargeSmall,
                  title: 'Ukuran teks',
                  trailingText: t.textScale.value.label,
                  onTap: () => Get.toNamed(textSizeRoute),
                ),
                _switchRow(
                  LucideIcons.layers,
                  'Kurangi transparansi',
                  t.reduceTransparency.value,
                  c.setReduceTransparency,
                  subtitle: 'Kaca jadi warna padat',
                ),
                NavRow(
                  icon: LucideIcons.calendarRange,
                  title: 'Awal bulan',
                  trailingText: 'Tanggal ${s.monthStartDay}',
                  onTap: _pickStartDay,
                ),
                NavRow(
                  icon: LucideIcons.hash,
                  title: 'Format angka',
                  trailingText: c.numberFormatLabel,
                  onTap: _pickNumberFormat,
                ),
                const NavRow(
                  icon: LucideIcons.banknote,
                  title: 'Mata uang',
                  trailingText: 'Rupiah (IDR)',
                ),
              ],
            ),
            ListGroup(
              title: 'Keamanan & data',
              children: [
                _switchRow(
                    LucideIcons.lock, 'Kunci aplikasi', s.appLock, c.togglePin,
                    subtitle: 'PIN 6 digit, sidik jari bila tersedia'),
                _switchRow(LucideIcons.eyeOff, 'Sembunyikan saldo saat dibuka',
                    s.hideOnOpen, c.toggleHideOnOpen),
                Obx(() {
                  final drive = Get.find<GoogleDriveService>();
                  return NavRow(
                    icon: LucideIcons.cloud,
                    title: 'Cadangan Google Drive',
                    trailingText:
                        drive.isConnected.value ? 'Terhubung' : 'Belum',
                    trailingColor:
                        drive.isConnected.value ? colorIncome : colorGrey,
                    onTap: () => Get.toNamed(backupRoute),
                  );
                }),
                NavRow(
                  icon: LucideIcons.fileSpreadsheet,
                  title: 'Ekspor & impor',
                  subtitle: 'Excel atau CSV',
                  onTap: () => Get.toNamed(exportRoute),
                ),
                _switchRow(LucideIcons.bell, 'Pengingat harian',
                    s.dailyReminder, c.toggleReminder),
                if (s.dailyReminder)
                  NavRow(
                    icon: LucideIcons.clock,
                    title: 'Jam pengingat',
                    trailingText: c.reminderLabel,
                    onTap: () => c.pickReminderTime(context),
                  ),
              ],
            ),
            ListGroup(
              title: 'Lainnya',
              children: [
                _switchRow(
                    LucideIcons.vibrate, 'Getaran', s.haptics, c.toggleHaptics),
                NavRow(
                  icon: LucideIcons.info,
                  title: 'Tentang Artavia',
                  trailingText: 'Versi 1.0.0',
                  onTap: _about,
                ),
              ],
            ),
            const SizedBox(height: 20),
            KButton.danger(
              label: 'Reset seluruh data',
              icon: LucideIcons.trash2,
              onPressed: c.isWorking.value ? null : c.resetAllData,
            ),
          ],
        );
      }),
    );
  }

  static Widget _switchRow(
      IconData icon, String title, bool value, ValueChanged<bool> onChanged,
      {String? subtitle}) {
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

  void _pickTheme() {
    _options<ThemePref>(
      title: 'Tema',
      options: const [ThemePref.system, ThemePref.dark, ThemePref.light],
      label: (p) => switch (p) {
        ThemePref.system => 'Ikuti sistem',
        ThemePref.dark => 'Gelap',
        ThemePref.light => 'Terang',
      },
      selected: controller.theme.pref.value,
      onSelected: controller.setTheme,
    );
  }

  void _pickNumberFormat() {
    _options<String>(
      title: 'Format angka',
      options: const ['dot', 'comma'],
      label: (f) => f == 'dot' ? '1.000.000 (titik)' : '1,000,000 (koma)',
      selected: controller.settings.numberFormat,
      onSelected: controller.setNumberFormat,
    );
  }

  void _pickStartDay() {
    final current = controller.settings.monthStartDay;
    showSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Mulai bulan pada tanggal',
                  style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 4),
              Text(
                  'Cocok untuk tanggal gajian. Berlaku untuk beranda, '
                  'laporan, dan anggaran.',
                  style: AppText.caption.muted),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (var d = 1; d <= 28; d++)
                    Material(
                      color: d == current ? colorAccent : colorSurface,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Get.back();
                          controller.setMonthStartDay(d);
                        },
                        child: Center(
                          child: Text('$d',
                              style: AppText.label.copyWith(
                                  color: d == current
                                      ? colorOnAccent
                                      : colorText)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _options<T>({
    required String title,
    required List<T> options,
    required String Function(T) label,
    required T selected,
    required ValueChanged<T> onSelected,
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
    );
  }

  void _about() {
    AppDialog.info(
      icon: LucideIcons.wallet,
      title: 'Artavia',
      message: 'Pencatat keuangan pribadi yang menyimpan data di HP-mu. '
          'Versi 1.0.0.',
    );
  }
}

/// "Status data" glass card: last backup + Cadangkan sekarang.
class _DataStatusCard extends StatelessWidget {
  const _DataStatusCard();

  @override
  Widget build(BuildContext context) {
    final last = SettingsService.to.lastBackupAt;
    final drive = Get.find<GoogleDriveService>();
    final connected = drive.isConnected.value;
    // "Hubungkan nanti" hides the nudge until Drive is connected (the
    // Cadangan Google Drive row below stays available).
    if (!connected && SettingsService.to.backupNudgeHidden) {
      return const SizedBox.shrink();
    }
    final tone = last == null ? colorWarning : colorIncome;
    final status = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration:
              BoxDecoration(color: softFill(tone), shape: BoxShape.circle),
          child: Icon(
              last == null ? LucideIcons.cloudAlert : LucideIcons.cloudCheck,
              size: 22,
              color: tone),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  last == null
                      ? 'Data hanya ada di HP ini'
                      : 'Data dicadangkan di Google Drive',
                  style: AppText.bodySmall.w600.copyWith(color: colorText)),
              Text(
                  last == null
                      ? 'Belum pernah dicadangkan'
                      : 'Terakhir ${DateFormat('d MMM, HH.mm', 'id_ID').format(last)}',
                  style: AppText.caption.onGlass),
            ],
          ),
        ),
        if (connected)
          KButton.tonal(
            label: 'Cadangkan',
            onPressed: () =>
                Get.toNamed(backupRoute, arguments: {'backupNow': true}),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GlassCard(
        child: connected
            ? status
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  status,
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      KButton.text(
                        label: 'Hubungkan nanti',
                        compact: true,
                        expand: false,
                        onPressed: () => SettingsService.to
                            .set(SettingsService.keyBackupNudgeHidden, 'true'),
                      ),
                      KButton.tonal(
                        label: 'Hubungkan',
                        onPressed: () => Get.toNamed(backupRoute),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
