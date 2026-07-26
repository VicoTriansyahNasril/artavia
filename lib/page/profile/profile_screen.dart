import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/page/profile/profile_controller.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 8),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildSection('Keuangan', [
            _menuItem(Icons.account_balance_wallet_rounded,
                'Manajemen Rekening',
                subtitle: 'Kelola dompet & rekening bank',
                onTap: () => Get.toNamed('/account-management')),
            _menuItem(Icons.pie_chart_rounded, 'Anggaran Bulanan',
                subtitle: 'Tetapkan batas belanja per kategori',
                onTap: () => Get.toNamed('/budget')),
            _menuItem(Icons.swap_horiz_rounded, 'Transfer Saldo',
                subtitle: 'Pindahkan saldo antar rekening',
                onTap: () => Get.toNamed('/transfer')),
          ]),
          const SizedBox(height: 8),
          _buildSection('Pencatatan', [
            _menuItem(Icons.category_rounded, 'Pengaturan Kategori',
                subtitle: 'Tambah atau edit kategori transaksi',
                onTap: () => Get.toNamed('/category-management')),
            _menuItem(Icons.book_rounded, 'Buku Kas',
                subtitle: 'Lihat semua transaksi dalam bentuk buku',
                onTap: () => Get.toNamed('/ledger')),
          ]),
          const SizedBox(height: 8),
          _buildSection('Pengaturan', [
            _menuItem(Icons.settings_rounded, 'Pengaturan Lainnya',
                subtitle: 'Notifikasi, keamanan, dan data',
                onTap: () => Get.toNamed('/settings')),
          ]),
          const SizedBox(height: 24),
          // App version
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Artavia',
                    style: TextStyle(
                        color: colorAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                SizedBox(height: 4),
                Text('Versi 1.0.0',
                    style: TextStyle(color: colorGrey, fontSize: 12)),
                SizedBox(height: 4),
                Text('Pencatat keuangan pribadi',
                    style: TextStyle(color: colorGrey, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorAccent.withOpacity(0.15),
            colorBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [colorAccent, Color(0xFFFFA000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_rounded,
                color: colorBlack, size: 32),
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
                          fontWeight: FontWeight.bold),
                    )),
                const SizedBox(height: 4),
                const Text('Pengelola Keuangan Pribadi',
                    style: TextStyle(color: colorGrey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: colorGrey, size: 20),
            onPressed: controller.loadStats,
            tooltip: 'Segarkan data',
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
          _statCard('Rekening', () => controller.totalAccounts.value.toString(),
              Icons.account_balance_wallet_rounded, colorAccent),
          const SizedBox(width: 10),
          _statCard('Kategori', () => controller.totalCategories.value.toString(),
              Icons.category_rounded, Colors.purple),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: colorCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.account_balance_rounded,
                        color: colorIncome, size: 14),
                    SizedBox(width: 4),
                    Text('Kekayaan Bersih',
                        style: TextStyle(color: colorGrey, fontSize: 10)),
                  ]),
                  const SizedBox(height: 6),
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
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

  Widget _statCard(String label, String Function() getValue,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Obx(() => Text(
                  getValue(),
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                )),
            Text(label,
                style: const TextStyle(color: colorGrey, fontSize: 10)),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  color: colorGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        Container(
          color: colorCard,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title,
      {String? subtitle, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorGrey, size: 20),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: colorWhite,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
          subtitle: subtitle != null
              ? Text(subtitle,
                  style: const TextStyle(color: colorGrey, fontSize: 11))
              : null,
          trailing: const Icon(Icons.chevron_right, color: colorGrey, size: 18),
          onTap: onTap ?? () {},
        ),
        Divider(
            color: colorBackground.withOpacity(0.8),
            height: 1,
            indent: 68),
      ],
    );
  }
}
