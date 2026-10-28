import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/profile/profile_controller.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/services/google_drive_service.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/components/menu_group.dart';

/// "Saya" tab: one summary card and three calm menu groups.
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadStats,
      backgroundColor: colorCard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        children: [
          ContentWidth(
            child: Column(
              children: [
                const _SummaryCard(),
                MenuGroup(title: 'Keuangan', children: [
                  MenuTile(
                    key: controller.keyProfileManageAccounts,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Rekening',
                    onTap: () => Get.toNamed(accountManagementRoute),
                  ),
                  MenuTile(
                    icon: Icons.donut_large_outlined,
                    title: 'Anggaran',
                    onTap: () => Get.toNamed(budgetRoute),
                  ),
                  MenuTile(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Transfer Saldo',
                    onTap: () => Get.toNamed(transferRoute),
                  ),
                  MenuTile(
                    icon: Icons.category_outlined,
                    title: 'Kategori',
                    onTap: () => Get.toNamed(categoryManagementRoute),
                  ),
                ]),
                MenuGroup(title: 'Data & Pengaturan', children: [
                  const _BackupTile(),
                  MenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    onTap: () => Get.toNamed(settingsRoute),
                  ),
                ]),
                if (kDebugMode)
                  MenuGroup(title: 'Developer', children: [
                    MenuTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Generate Dummy Data',
                      onTap: () async {
                        final ok = await AppDialog.confirm(
                          title: 'Generate Dummy Data',
                          message:
                              'Ini akan menambahkan data dummy ke database saat ini. Lanjutkan?',
                        );
                        if (ok) controller.generateDummyData();
                      },
                    ),
                  ]),
                const SizedBox(height: 32),
                const Text('Artavia · Versi 1.0.0',
                    style: TextStyle(color: colorGrey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar, name and net worth with account/category counts in one card.
class _SummaryCard extends GetView<ProfileController> {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(() {
        final worth = controller.netWorth.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: colorAccentDim,
                  child:
                      Icon(Icons.person_rounded, color: colorAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.userName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: colorText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(),
            ),
            const Text('Kekayaan Bersih',
                style: TextStyle(color: colorGrey, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyService.to.format(worth),
                style: TextStyle(
                  color: worth < 0 ? colorExpense : colorText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${controller.totalAccounts.value} rekening · '
              '${controller.totalCategories.value} kategori',
              style: const TextStyle(color: colorGrey, fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}

/// One row for Google Drive; the actions live in a bottom sheet.
class _BackupTile extends GetView<ProfileController> {
  const _BackupTile();

  @override
  Widget build(BuildContext context) {
    final drive = Get.find<GoogleDriveService>();
    return Obx(() => MenuTile(
          icon: Icons.cloud_outlined,
          title: 'Cadangan Google Drive',
          value: drive.isConnected.value ? 'Terhubung' : 'Belum',
          valueColor: drive.isConnected.value ? colorIncome : colorGrey,
          onTap: () => _showActions(drive),
        ));
  }

  void _showActions(GoogleDriveService drive) {
    void run(VoidCallback action) {
      Get.back();
      action();
    }

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drive.isConnected.value
                ? [
                    _action(Icons.cloud_upload_outlined, 'Backup sekarang',
                        () => run(controller.backupData)),
                    _action(Icons.cloud_download_outlined, 'Restore dari Drive',
                        () => run(_confirmRestore)),
                    _action(Icons.link_off_rounded, 'Putuskan koneksi',
                        () => run(controller.disconnectGoogleDrive),
                        danger: true),
                  ]
                : [
                    _action(Icons.login_rounded, 'Hubungkan Google Drive',
                        () => run(controller.connectGoogleDrive)),
                  ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRestore() async {
    final ok = await AppDialog.confirm(
      title: 'Konfirmasi Restore',
      message:
          'Data lokal akan ditimpa dengan data dari Google Drive. Lanjutkan?',
      confirmLabel: 'Restore',
      destructive: true,
    );
    if (ok) controller.restoreData();
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? colorExpense : colorText;
    return ListTile(
      leading: Icon(icon, color: danger ? colorExpense : colorGrey),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
