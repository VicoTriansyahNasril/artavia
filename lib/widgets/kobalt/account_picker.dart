import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/app_scaffold.dart';
import 'package:artavia/widgets/kobalt/k_button.dart';
import 'package:artavia/widgets/kobalt/k_controls.dart';
import 'package:artavia/widgets/kobalt/list_group.dart';
import 'package:artavia/widgets/kobalt/sheet.dart';

/// Bottom sheet listing accounts with balances (Catat, Transfer). The eye
/// flips the global mask in place.
void showAccountPicker({
  required List<Map<String, dynamic>> accounts,
  required int? selectedId,
  required ValueChanged<int> onSelect,
  VoidCallback? onCreate,
  String title = 'Pilih rekening',
}) {
  showSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The eye flips the global mask right here, so hidden balances
            // can be checked without leaving Catat.
            Obx(() {
              final masked = PrivacyService.to.masked.value;
              return Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: AppText.title3.copyWith(color: colorText)),
                  ),
                  KIconButton(
                    icon: masked ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: masked ? colorAccent : null,
                    semanticLabel:
                        masked ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                    onPressed: PrivacyService.to.toggle,
                  ),
                ],
              );
            }),
            const SizedBox(height: 4),
            Flexible(
              child: SingleChildScrollView(
                child: Obx(() {
                  PrivacyService.to.masked.value;
                  return ListGroup(
                    children: [
                      for (var i = 0; i < accounts.length; i++)
                        NavRow(
                          leading: CategoryIcon.round(
                            iconKey: accounts[i]['icon_key'] as String? ??
                                IconRegistry.accountTypeKey(
                                    accounts[i]['type'] as String? ?? ''),
                            color: themedColor(accounts[i]['color_val'] as int?,
                                fallbackIndex: i),
                          ),
                          title: accounts[i]['name'] as String,
                          subtitle: CurrencyService.to
                              .money(accounts[i]['balance'] as int? ?? 0),
                          showChevron: false,
                          trailing:
                              KRadio(selected: accounts[i]['id'] == selectedId),
                          onTap: () {
                            onSelect(accounts[i]['id'] as int);
                            Get.back();
                          },
                        ),
                    ],
                  );
                }),
              ),
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 12),
              KButton.text(
                label: 'Tambah rekening',
                icon: LucideIcons.plus,
                onPressed: () {
                  Get.back();
                  onCreate();
                },
              ),
            ],
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
