import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/profile/profile_controller.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/core/services/google_drive_service.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildSection('Keuangan', [
            _menuItem(
              Icons.account_balance_wallet_rounded,
              const Color(0xFFF5C842),
              'Manajemen Rekening',
              subtitle: 'Kelola dompet & rekening bank',
              onTap: () => Get.toNamed('/account-management'),
              key: controller.keyProfileManageAccounts,
            ),
            _menuItem(
              Icons.pie_chart_rounded,
              const Color(0xFFBA68C8),
              'Anggaran Bulanan',
              subtitle: 'Tetapkan batas belanja per kategori',
              onTap: () => Get.toNamed('/budget'),
            ),
            _menuItem(
              Icons.swap_horiz_rounded,
              const Color(0xFF64B5F6),
              'Transfer Saldo',
              subtitle: 'Pindahkan saldo antar rekening',
              onTap: () => Get.toNamed('/transfer'),
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('Pencatatan', [
            _menuItem(
              Icons.category_rounded,
              const Color(0xFF81C784),
              'Pengaturan Kategori',
              subtitle: 'Tambah atau edit kategori transaksi',
              onTap: () => Get.toNamed('/category-management'),
            ),
            _menuItem(
              Icons.book_rounded,
              const Color(0xFF4DB6AC),
              'Buku Kas',
              subtitle: 'Lihat semua transaksi dalam satu buku',
              onTap: () => Get.toNamed('/ledger'),
            ),
          ]),
          const SizedBox(height: 12),
          _buildBackupSection(),
          const SizedBox(height: 12),
          _buildSection('Pengaturan', [
            _menuItem(
              Icons.settings_rounded,
              colorGrey,
              'Pengaturan Lainnya',
              subtitle: 'Notifikasi, keamanan, dan data',
              onTap: () => Get.toNamed('/settings'),
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('Developer', [
            _menuItem(
              Icons.bug_report_rounded,
              Colors.redAccent,
              'Generate Dummy Data',
              subtitle: 'Tambah data dummy ke database saat ini',
              onTap: () {
                Get.defaultDialog(
                  title: 'Generate Dummy Data',
                  middleText: 'Ini akan menambahkan data dummy ke database saat ini. Lanjutkan?',
                  textConfirm: 'Ya',
                  textCancel: 'Batal',
                  confirmTextColor: Colors.white,
                  onConfirm: () {
                    Get.back();
                    controller.generateDummyData();
                  },
                );
              },
            ),
          ]),
          const SizedBox(height: 28),
          const _AppFooter(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1A0A), colorBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [colorAccent, Color(0xFFE5A800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_rounded,
                color: colorOnAccent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.userName.value,
                      style: const TextStyle(
                        color: colorWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(height: 3),
                const Text(
                  'Pengelola Keuangan Pribadi',
                  style: TextStyle(color: colorGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: colorGrey, size: 20),
            onPressed: controller.loadStats,
            tooltip: 'Segarkan',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(
            'Rekening',
            () => controller.totalAccounts.value.toString(),
            Icons.account_balance_wallet_rounded,
            const Color(0xFFF5C842),
          ),
          const SizedBox(width: 10),
          _statCard(
            'Kategori',
            () => controller.totalCategories.value.toString(),
            Icons.category_rounded,
            const Color(0xFFBA68C8),
          ),
          const SizedBox(width: 10),
          // Net worth card (wider)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: colorCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.account_balance_rounded,
                        color: colorIncome, size: 13),
                    SizedBox(width: 4),
                    Text('Kekayaan Bersih',
                        style: TextStyle(color: colorGrey, fontSize: 10)),
                  ]),
                  const SizedBox(height: 7),
                  Obx(() => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyService.to.formatWithoutSymbol(
                              controller.netWorth.value),
                          style: TextStyle(
                            color: controller.netWorth.value >= 0
                                ? colorIncome
                                : colorExpense,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String Function() getValue,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(height: 8),
            Obx(() => Text(
                  getValue(),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            Text(
              label,
              style: const TextStyle(color: colorGrey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: colorGrey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Material(
          color: colorCard,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    Color iconColor,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Key? key,
  }) {
    return Column(
      key: key,
      children: [
        ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: colorWhite,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: colorGrey, fontSize: 11),
                )
              : null,
          trailing: const Icon(Icons.chevron_right, color: colorGrey, size: 18),
          onTap: onTap ?? () {},
        ),
        const Divider(indent: 66, height: 1, color: colorDivider),
      ],
    );
  }

  Widget _buildBackupSection() {
    final driveService = Get.find<GoogleDriveService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'CLOUD BACKUP',
            style: TextStyle(
              color: colorGrey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Material(
          color: colorCard,
          child: Column(
            children: [
              Obx(() => driveService.isConnected.value
                  ? _menuItem(
                      Icons.cloud_done_rounded,
                      Colors.green,
                      'Terhubung ke Google Drive',
                      subtitle: 'Ketuk untuk memutuskan koneksi',
                      onTap: controller.disconnectGoogleDrive,
                    )
                  : _menuItem(
                      Icons.cloud_off_rounded,
                      Colors.grey,
                      'Hubungkan ke Google Drive',
                      subtitle: 'Login untuk mencadangkan data',
                      onTap: controller.connectGoogleDrive,
                    )),
              Obx(() => driveService.isConnected.value
                  ? Column(
                      children: [
                        _menuItem(
                          Icons.upload_file_rounded,
                          Colors.blue,
                          'Backup Data Sekarang',
                          subtitle: 'Simpan data ke cloud',
                          onTap: controller.backupData,
                        ),
                        _menuItem(
                          Icons.download_rounded,
                          Colors.orange,
                          'Restore Data',
                          subtitle: 'Pulihkan data dari cloud',
                          onTap: () {
                            Get.defaultDialog(
                              title: 'Konfirmasi Restore',
                              middleText: 'Data lokal akan ditimpa dengan data dari Google Drive. Lanjutkan?',
                              textConfirm: 'Ya',
                              textCancel: 'Batal',
                              confirmTextColor: Colors.white,
                              onConfirm: () {
                                Get.back();
                                controller.restoreData();
                              },
                            );
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── App Footer ───────────────────────────────────────────────────────────────

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Artavia',
          style: TextStyle(
            color: colorAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Versi 1.0.0',
          style: TextStyle(color: colorGrey, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          'Pencatat keuangan pribadi',
          style: TextStyle(color: colorGrey, fontSize: 11),
        ),
      ],
    );
  }
}
