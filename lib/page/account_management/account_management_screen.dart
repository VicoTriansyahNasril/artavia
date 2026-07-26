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
        elevation: 0,
        title: const Text(
          'Mengelola Rekening',
          style: TextStyle(
            color: colorWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.resetForm();
          Get.toNamed('/add-account');
        },
        backgroundColor: colorAccent,
        icon: const Icon(Icons.add, color: colorOnAccent),
        label: const Text(
          'Tambahkan',
          style: TextStyle(
            color: colorOnAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: colorGrey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada rekening',
            style: TextStyle(
              color: colorWhite,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ketuk + untuk menambah rekening baru',
            style: TextStyle(color: colorGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: controller.accountGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = controller.accountGroups[groupIndex];
        final accounts = group['accounts'] as List;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                (group['groupName'] as String).toUpperCase(),
                style: const TextStyle(
                  color: colorGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Material(
              color: colorCard,
              child: Column(
                children: accounts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final acc = entry.value as Map<String, dynamic>;
                  final iconCode = acc['icon_code'] as int?;
                  final iconPath = acc['icon_path'] as String?;
                  final colorVal = acc['color_val'] as int? ?? 0xFFFFCA28;
                  final color = Color(colorVal);
                  final isExcluded = acc['is_excluded'] as bool? ?? false;

                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(color: colorBackground, height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CategoryIcon(
                            iconCode: iconCode,
                            iconPath: iconPath,
                            color: color,
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              acc['name'] as String,
                              style: const TextStyle(
                                color: colorWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (isExcluded) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorGrey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Dikecualikan',
                                  style: TextStyle(
                                    color: colorGrey,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Text(
                                acc['currency_code'] as String? ?? 'IDR',
                                style: const TextStyle(
                                  color: colorAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                CurrencyService.to.formatWithoutSymbol(acc['balance']),
                                style: const TextStyle(
                                  color: colorGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: colorGrey,
                                size: 20,
                              ),
                              onPressed: () {
                                controller.startEditAccount(acc);
                                Get.toNamed('/add-account');
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: colorExpense,
                                size: 20,
                              ),
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
