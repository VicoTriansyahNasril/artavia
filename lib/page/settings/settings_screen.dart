import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/page/settings/settings_controller.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/components/menu_group.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = controller.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Obx(() => AbsorbPointer(
            absorbing: controller.isWorking.value,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                ContentWidth(
                  child: Column(children: [
                    MenuGroup(title: 'Pencatatan', children: [
                      MenuTile(
                          icon: Icons.repeat_rounded,
                          title: 'Transaksi Berulang',
                          onTap: () => Get.toNamed(recurringRoute)),
                      MenuTile(
                          icon: Icons.event_outlined,
                          title: 'Mulai Bulan Pada',
                          value: 'Tanggal ${s.monthStartDay}',
                          onTap: () => _pickStartDay(context)),
                      MenuSwitchTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Pengingat Harian',
                          value: s.dailyReminder,
                          onChanged: controller.toggleReminder),
                      if (s.dailyReminder)
                        MenuTile(
                            icon: Icons.schedule_rounded,
                            title: 'Jam Pengingat',
                            value: controller.reminderLabel,
                            onTap: () => controller.pickReminderTime(context)),
                    ]),
                    MenuGroup(title: 'Keamanan & Data', children: [
                      MenuSwitchTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Kunci Aplikasi (PIN)',
                          value: s.appLock,
                          onChanged: controller.togglePin),
                      MenuTile(
                          icon: Icons.cloud_outlined,
                          title: 'Cadangkan Data',
                          value: 'Google Drive',
                          onTap: controller.openBackup),
                      MenuTile(
                          icon: Icons.file_upload_outlined,
                          title: 'Ekspor CSV',
                          onTap: controller.exportCsv),
                      MenuTile(
                          icon: Icons.file_download_outlined,
                          title: 'Impor CSV',
                          onTap: controller.importCsv),
                      MenuTile(
                          icon: Icons.delete_outline_rounded,
                          title: 'Reset Seluruh Data',
                          danger: true,
                          onTap: controller.resetAllData),
                    ]),
                    MenuGroup(title: 'Tampilan & Suara', children: [
                      MenuTile(
                          icon: Icons.pin_outlined,
                          title: 'Format Angka',
                          value: controller.numberFormatLabel,
                          onTap: () => _pickNumberFormat(context)),
                      MenuSwitchTile(
                          icon: Icons.volume_up_outlined,
                          title: 'Efek Suara',
                          value: s.soundEffect,
                          onChanged: controller.toggleSound),
                    ]),
                    if (controller.isWorking.value)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                  ]),
                ),
              ],
            ),
          )),
    );
  }

  void _pickStartDay(BuildContext context) {
    final current = controller.settings.monthStartDay;
    _showOptions(
      context,
      title: 'Mulai bulan pada tanggal',
      options: [for (var d = 1; d <= 28; d++) d],
      label: (d) => '$d',
      isSelected: (d) => d == current,
      onSelected: controller.setMonthStartDay,
      grid: true,
    );
  }

  void _pickNumberFormat(BuildContext context) {
    final current = controller.settings.numberFormat;
    _showOptions(
      context,
      title: 'Format angka',
      options: const ['dot', 'comma'],
      label: (f) => f == 'dot' ? '1.000.000 (titik)' : '1,000,000 (koma)',
      isSelected: (f) => f == current,
      onSelected: controller.setNumberFormat,
    );
  }

  void _showOptions<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) label,
    required bool Function(T) isSelected,
    required ValueChanged<T> onSelected,
    bool grid = false,
  }) {
    void choose(T value) {
      Get.back();
      onSelected(value);
    }

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: colorText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (grid)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options
                      .map((o) => ChoiceChip(
                            label: SizedBox(
                                width: 24,
                                child: Text(label(o),
                                    textAlign: TextAlign.center)),
                            selected: isSelected(o),
                            showCheckmark: false,
                            onSelected: (_) => choose(o),
                          ))
                      .toList(),
                )
              else
                ...options.map((o) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(label(o)),
                      trailing: isSelected(o)
                          ? const Icon(Icons.check_rounded, color: colorAccent)
                          : null,
                      onTap: () => choose(o),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
