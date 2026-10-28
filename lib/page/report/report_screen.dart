import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/page/report/report_controller.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/commons/common.dart';

/// "Aset" tab: net worth (shared rule, FR-013) and the account list.
class ReportScreen extends GetView<ReportController> {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadData,
      backgroundColor: colorCard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: const [
          _NetWorthCard(),
          SizedBox(height: 12),
          _ActionRow(),
          _AccountList(),
        ],
      ),
    );
  }
}

class _NetWorthCard extends GetView<ReportController> {
  const _NetWorthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorCard, borderRadius: BorderRadius.circular(12)),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kekayaan Bersih',
                  style: TextStyle(color: colorGrey, fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                CurrencyService.to.format(controller.kekayaanBersih.value),
                style: const TextStyle(
                    color: colorText,
                    fontSize: 26,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _figure('Total Aset', controller.totalAset.value, colorIncome),
                _figure('Total Liabilitas', controller.totalLiabilitas.value,
                    colorExpense),
              ]),
            ],
          )),
    );
  }

  Widget _figure(String label, int value, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: colorGrey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(CurrencyService.to.formatWithoutSymbol(value),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => AccountManagementController.openEditor(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Rekening'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(accountManagementRoute),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Kelola'),
          ),
        ),
      ],
    );
  }
}

class _AccountList extends GetView<ReportController> {
  const _AccountList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.accountGroups.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: colorGrey),
            SizedBox(height: 12),
            Text('Belum ada rekening',
                style:
                    TextStyle(color: colorText, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('Tambahkan rekening untuk mulai mencatat',
                style: TextStyle(color: colorGrey, fontSize: 13)),
          ]),
        );
      }
      return Column(
        children: controller.accountGroups.map((group) {
          final accounts =
              (group['accounts'] as List).cast<Map<String, dynamic>>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                child: Row(children: [
                  Text((group['groupName'] as String).toUpperCase(),
                      style: const TextStyle(
                          color: colorGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8)),
                  const Spacer(),
                  Text(
                      CurrencyService.to
                          .formatWithoutSymbol(group['total'] as int),
                      style: const TextStyle(color: colorGrey, fontSize: 11)),
                ]),
              ),
              Material(
                color: colorCard,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (var i = 0; i < accounts.length; i++) ...[
                    if (i > 0) const Divider(indent: 68),
                    _AccountTile(account: accounts[i]),
                  ],
                ]),
              ),
            ],
          );
        }).toList(),
      );
    });
  }
}

class _AccountTile extends StatelessWidget {
  final Map<String, dynamic> account;

  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final color =
        Color(account['color_val'] as int? ?? categoryPalette.first.toARGB32());
    final balance = account['balance'] as int? ?? 0;
    final excluded = isExcludedAccount(account);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => AccountManagementController.openEditor(account),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CategoryIcon(
          iconCode: account['icon_code'] as int?,
          iconPath: account['icon_path'] as String?,
          color: color,
          size: 20,
        ),
      ),
      title: Text(account['name'] as String,
          style: const TextStyle(
              color: colorText, fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: excluded
          ? const Text('Tidak dihitung dalam total',
              style: TextStyle(color: colorGrey, fontSize: 11))
          : null,
      trailing: Text(
        CurrencyService.to.formatWithoutSymbol(balance),
        style: TextStyle(
          color: balance < 0 ? colorExpense : colorText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
