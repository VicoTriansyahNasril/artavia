import 'package:flutter/material.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:get/get.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/widgets/commons/common.dart';

class AccountManagementScreen
    extends GetView<AccountManagementController> {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        title: const Text('Manajemen Rekening',
            style: TextStyle(color: colorWhite, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorWhite),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.accountGroups.isEmpty) {
          return _buildEmptyState();
        }
        return _buildAccountList();
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.resetForm();
          Get.toNamed('/add-account');
        },
        backgroundColor: colorAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: colorBlack),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: colorGrey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Belum ada rekening',
              style: TextStyle(color: colorGrey, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Ketuk + untuk menambah rekening baru',
              style: TextStyle(color: colorGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: controller.accountGroups.length,
      itemBuilder: (context, index) {
        final group = controller.accountGroups[index];
        final accounts = group['accounts'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                group['groupName'] as String,
                style: const TextStyle(
                    color: colorGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
            Container(
              color: colorCard,
              child: Column(
                children: accounts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final acc = entry.value as Map<String, dynamic>;
                  final iconCode =
                      acc['icon_code'] as int? ?? 0xe4fc;
                  final colorVal =
                      acc['color_val'] as int? ?? 0xFFFFCA28;
                  final iconData =
                      IconData(iconCode, fontFamily: 'MaterialIcons');
                  final color = Color(colorVal);
                  final isExcluded = acc['is_excluded'] as bool? ?? false;

                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(color: colorBackground, height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(iconData, color: color, size: 22),
                        ),
                        title: Row(
                          children: [
                            Text(acc['name'] as String,
                                style: const TextStyle(
                                    color: colorWhite,
                                    fontWeight: FontWeight.w600)),
                            if (isExcluded) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorGrey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Dikecualikan',
                                    style: TextStyle(
                                        color: colorGrey, fontSize: 9)),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          CurrencyService.to
                              .formatWithoutSymbol(acc['balance']),
                          style: const TextStyle(
                              color: colorGrey, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: colorGrey, size: 20),
                              onPressed: () {
                                controller.startEditAccount(acc);
                                Get.toNamed('/add-account');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: colorExpense, size: 20),
                              onPressed: () => controller.deleteAccount(
                                  acc['id'] as int, acc['name'] as String),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
