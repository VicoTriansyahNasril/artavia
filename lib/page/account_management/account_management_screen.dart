import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/page/account_management/account_management_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Standalone route (from Pengaturan › Keuangan) around [AccountListView].
class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Rekening',
      actions: [
        KIconButton(
          icon: LucideIcons.plus,
          semanticLabel: 'Tambah rekening',
          onPressed: AccountManagementController.openEditor,
        ),
      ],
      body: AccountListView(),
    );
  }
}

/// Rekening tab (board "Rekening"): Kekayaan bersih hero, collapsible
/// groups with subtotals, and the archived link.
class AccountListView extends GetView<AccountManagementController> {
  const AccountListView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadAccounts,
      backgroundColor: colorCard,
      color: colorAccent,
      child: Obx(() {
        PrivacyService.to.masked.value;
        controller.collapsed.length;
        final w = controller.worth.value;
        final groups = controller.groups;
        final money = CurrencyService.to;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            BalanceHero(
              label: 'Kekayaan bersih',
              amount: w.net,
              figures: [
                HeroFigure(
                    label: 'Aset',
                    amount: w.asset,
                    color: colorIncome,
                    icon: LucideIcons.trendingUp),
                HeroFigure(
                    label: 'Liabilitas',
                    amount: w.liability,
                    color: colorDanger,
                    icon: LucideIcons.trendingDown),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerRight,
              child: KButton.text(
                label: 'Tambah rekening',
                icon: LucideIcons.plus,
                compact: true,
                expand: false,
                onPressed: AccountManagementController.openEditor,
              ),
            ),
            if (groups.isEmpty && !controller.isLoading.value)
              const EmptyState(
                icon: LucideIcons.wallet,
                title: 'Belum ada rekening',
                body: 'Tambahkan dompet, bank, atau e-wallet pertamamu.',
                action: KButton.tonal(
                  label: 'Tambah rekening',
                  onPressed: AccountManagementController.openEditor,
                ),
              ),
            for (final g in groups) _GroupSection(group: g),
            if (controller.archived.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: KButton.text(
                  label: '${controller.archived.length} rekening diarsipkan',
                  icon: LucideIcons.archive,
                  compact: true,
                  expand: false,
                  onPressed: _showArchived,
                ),
              ),
            ],
            if (money.masked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Nominal disembunyikan.',
                    textAlign: TextAlign.center, style: AppText.caption.muted),
              ),
          ],
        );
      }),
    );
  }

  void _showArchived() {
    showSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Rekening diarsipkan',
                      style: AppText.title3.copyWith(color: colorText)),
                  const SizedBox(height: 4),
                  Text('Tidak muncul di pilihan dan tidak dihitung.',
                      style: AppText.caption.muted),
                  const SizedBox(height: 12),
                  if (controller.archived.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Tidak ada lagi',
                          textAlign: TextAlign.center,
                          style: AppText.bodySmall.muted),
                    )
                  else
                    ListGroup(
                      children: [
                        for (final a in controller.archived)
                          NavRow(
                            leading: _accountIcon(a, 0),
                            title: a['name'] as String,
                            subtitle: CurrencyService.to
                                .money(a['balance'] as int? ?? 0),
                            showChevron: false,
                            trailing: KButton.tonal(
                              label: 'Pulihkan',
                              onPressed: () => controller.setArchived(a, false),
                            ),
                          ),
                      ],
                    ),
                ],
              )),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

Widget _accountIcon(Map<String, dynamic> a, int index) => CategoryIcon.round(
      iconKey: a['icon_key'] as String? ??
          IconRegistry.accountTypeKey(a['type'] as String? ?? ''),
      iconPath: a['icon_path'] as String?,
      color: themedColor(a['color_val'] as int?, fallbackIndex: index),
    );

class _GroupSection extends GetView<AccountManagementController> {
  final AccountGroupView group;
  const _GroupSection({required this.group});

  @override
  Widget build(BuildContext context) {
    final collapsed = controller.collapsed.contains(group.name);
    final money = CurrencyService.to;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: !collapsed,
          label: '${group.name}, ${group.accounts.length} rekening',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => controller.toggleGroup(group.name),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Row(
                children: [
                  Icon(
                      collapsed
                          ? LucideIcons.chevronRight
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: colorGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${group.name} · ${group.accounts.length}',
                        style: AppText.label.copyWith(color: colorGrey)),
                  ),
                  Text(money.money(group.subtotal),
                      style: AppText.label.copyWith(
                          color: group.subtotal < 0 ? colorDanger : colorText)),
                ],
              ),
            ),
          ),
        ),
        if (!collapsed)
          ListGroup(
            children: [
              for (var i = 0; i < group.accounts.length; i++)
                _AccountRow(account: group.accounts[i], index: i),
            ],
          ),
      ],
    );
  }
}

class _AccountRow extends GetView<AccountManagementController> {
  final Map<String, dynamic> account;
  final int index;
  const _AccountRow({required this.account, required this.index});

  @override
  Widget build(BuildContext context) {
    final balance = account['balance'] as int? ?? 0;
    final excluded = account['is_excluded'] == 1;
    final limit = account['credit_limit'] as int?;
    final due = account['due_day'] as int?;
    final money = CurrencyService.to;
    final subtitle = [
      account['type'] as String? ?? '',
      if (limit != null && limit > 0) 'Limit ${money.short(limit)}',
      if (due != null) 'Jatuh tempo tgl $due',
      if (excluded) 'Tidak dihitung',
    ].where((e) => e.isNotEmpty).join(' · ');
    return NavRow(
      leading: _accountIcon(account, index),
      title: account['name'] as String,
      subtitle: subtitle,
      showChevron: false,
      trailing: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(money.money(balance),
            style: AppText.rowAmount
                .copyWith(color: balance < 0 ? colorDanger : colorText)),
      ),
      onTap: () => AccountManagementController.openEditor(account),
    );
  }
}
