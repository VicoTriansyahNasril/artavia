import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/services/privacy_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/home/home_controller.dart';
import 'package:artavia/page/account_management/account_management_screen.dart';
import 'package:artavia/page/report/report_screen.dart';
import 'package:artavia/page/settings/settings_screen.dart';
import 'package:artavia/page/routes.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static const _titles = ['Transaksi', 'Laporan', 'Rekening', 'Pengaturan'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      extendBody: true,
      body: Stack(
        children: [
          const AmbientOrb(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Obx(() => _TabHeader(index: controller.currentIndex.value)),
                Expanded(
                  child: Obx(() => IndexedStack(
                        index: controller.currentIndex.value,
                        children: const [
                          HistoryView(),
                          ReportScreen(),
                          AccountListView(),
                          SettingsView(),
                        ],
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() => KBottomNav(
            index: controller.currentIndex.value,
            onTap: controller.changePage,
            onCatat: _openCatat,
          )),
    );
  }

  /// FR-018: Catat needs an account first.
  void _openCatat() {
    if (controller.hasAccounts.value == false) {
      controller.changePage(0);
      AppToast.info('Buat rekening dulu',
          'Isi rekening pertamamu di beranda untuk mulai mencatat.');
      return;
    }
    Get.toNamed(addTransactionRoute);
  }
}

/// Per-tab title row; money tabs get the privacy eye, Transaksi also gets
/// Cari and Kalender.
class _TabHeader extends StatelessWidget {
  final int index;
  const _TabHeader({required this.index});

  @override
  Widget build(BuildContext context) {
    final masked = PrivacyService.to.masked.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(HomeScreen._titles[index],
                  style: AppText.title2.copyWith(color: colorText)),
            ),
            if (index < 3)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: masked ? colorAccentDim : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: KIconButton(
                  icon: masked ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: masked ? colorAccent : null,
                  semanticLabel:
                      masked ? 'Tampilkan nominal' : 'Sembunyikan nominal',
                  onPressed: PrivacyService.to.toggle,
                ),
              ),
            if (index == 0) ...[
              KIconButton(
                icon: LucideIcons.search,
                semanticLabel: 'Cari transaksi',
                onPressed: () => Get.toNamed(searchRoute),
              ),
              KIconButton(
                icon: LucideIcons.calendarDays,
                semanticLabel: 'Kalender',
                onPressed: () => Get.toNamed(calendarRoute),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Transaksi tab (board "Transaksi").
class HistoryView extends GetView<HomeController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadData,
      backgroundColor: colorCard,
      color: colorAccent,
      child: Obx(() {
        if (controller.hasAccounts.value == false) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: const [_WelcomeCard()],
          );
        }
        final groups = controller.dayGroups;
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          itemCount: groups.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return const _HistoryHeader();
            return _DaySection(group: groups[index - 1]);
          },
        );
      }),
    );
  }
}

class _HistoryHeader extends GetView<HomeController> {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final empty = controller.dayGroups.isEmpty;
      final b = controller.budget.value;
      final insight = controller.insight.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BalanceHero(
            header: _PeriodRow(greeting: controller.greeting),
            label: 'Sisa periode ini',
            amount: controller.saldoTotal.value,
            figures: [
              HeroFigure(
                  label: 'Pemasukan',
                  amount: controller.totalPemasukan.value,
                  color: colorIncome,
                  icon: LucideIcons.arrowDownLeft),
              HeroFigure(
                  label: 'Pengeluaran',
                  amount: controller.totalPengeluaran.value,
                  color: colorDanger,
                  icon: LucideIcons.arrowUpRight),
            ],
            insight: insight.text,
            insightIcon: insight.isLower
                ? LucideIcons.trendingDown
                : LucideIcons.trendingUp,
          ),
          if (b.summary.total > 0) ...[
            const SizedBox(height: 12),
            _BudgetCard(budget: b),
          ],
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in HomeController.filters) ...[
                  KChip(
                    label: f,
                    selected: controller.filter.value == f,
                    onTap: () => controller.setFilter(f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (controller.isLoading.value && empty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (empty)
            EmptyState(
              icon: LucideIcons.receiptText,
              title: controller.filter.value == 'Semua'
                  ? 'Belum ada transaksi'
                  : 'Tidak ada ${controller.filter.value.toLowerCase()}',
              body: 'Ketuk tombol + untuk mulai mencatat.',
            ),
        ],
      );
    });
  }
}

/// Greeting and ‹ Oktober 2026 › inside the hero card.
class _PeriodRow extends StatelessWidget {
  final String greeting;
  const _PeriodRow({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final service = PeriodService.to;
    return Row(
      children: [
        Expanded(
          child: Text(greeting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodySmall.w600.copyWith(color: colorText)),
        ),
        KIconButton(
          icon: LucideIcons.chevronLeft,
          size: 18,
          semanticLabel: 'Periode sebelumnya',
          onPressed: () => service.shift(-1),
        ),
        Flexible(
          flex: 2,
          child: GestureDetector(
            onTap: showPeriodPicker,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Obx(() => Text(service.active.value.longLabel,
                  style: AppText.label.copyWith(color: colorText))),
            ),
          ),
        ),
        KIconButton(
          icon: LucideIcons.chevronRight,
          size: 18,
          semanticLabel: 'Periode berikutnya',
          onPressed: () => service.shift(1),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final HomeBudget budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final s = budget.summary;
    final level = budgetStatus(s.used, s.total);
    final tone = switch (level) {
      BudgetLevel.over => KTone.danger,
      BudgetLevel.near => KTone.warning,
      BudgetLevel.safe => KTone.accent,
    };
    final attentionColor =
        budget.attentionLevel == BudgetLevel.over ? colorDanger : colorWarning;
    final money = CurrencyService.to;
    return GestureDetector(
      onTap: () => Get.toNamed(budgetRoute),
      child: KCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Anggaran bulan ini',
                      style: AppText.bodySmall.w600.copyWith(color: colorText)),
                ),
                Text('${(s.ratio * 100).round()}%',
                    style: AppText.label.copyWith(color: toneColor(tone))),
              ],
            ),
            const SizedBox(height: 4),
            Text('${money.money(s.used)} dari ${money.money(s.total)}',
                style: AppText.caption.muted),
            const SizedBox(height: 10),
            KProgress(value: s.ratio, tone: tone),
            if (budget.attentionName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(LucideIcons.triangleAlert,
                      size: 14, color: attentionColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      budget.attentionLevel == BudgetLevel.over
                          ? '${budget.attentionName} melewati batas'
                          : '${budget.attentionName} hampir mencapai batas',
                      style: AppText.caption.copyWith(color: attentionColor),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DayGroup group;
  const _DaySection({required this.group});

  @override
  Widget build(BuildContext context) {
    final net = group.income - group.expense;
    return ListGroup(
      title: group.label,
      titleAction: group.income == 0 && group.expense == 0
          ? null
          : Text(CurrencyService.to.money(net, signed: true),
              style: AppText.caption.copyWith(
                  color: net >= 0 ? colorIncome : colorGrey,
                  fontWeight: FontWeight.w600)),
      children: [for (final tx in group.items) TransactionItem(tx: tx)],
    );
  }
}

/// New-user card with the first-account form (FR-018).
class _WelcomeCard extends GetView<HomeController> {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: colorAccentDim, shape: BoxShape.circle),
                  child: Icon(LucideIcons.wallet, color: colorAccent),
                ),
              ),
              const SizedBox(height: 14),
              Text('Mulai dengan satu rekening',
                  style: AppText.title1.copyWith(color: colorText)),
              const SizedBox(height: 6),
              Text(
                  'Rekening adalah tempat uangmu berada: dompet, bank, atau '
                  'e-wallet. Kamu bisa menambah yang lain nanti.',
                  style: AppText.bodySmall.onGlass),
              const SizedBox(height: 18),
              KField(
                label: 'Nama rekening',
                hint: 'Mis. Dompet, BCA, GoPay',
                maxLength: 30,
                onChanged: (v) => controller.starterName.value = v,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('Jenis', style: AppText.caption.muted),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in HomeController.starterTypes.keys)
                    KChip(
                      label: t,
                      selected: controller.starterType.value == t,
                      onTap: () => controller.starterType.value = t,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              KField(
                label: 'Saldo awal',
                hint: '0',
                prefix: Text('Rp', style: AppText.body.muted),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                onChanged: (v) =>
                    controller.starterBalance.value = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 18),
              KButton(
                label: 'Buat rekening',
                icon: LucideIcons.plus,
                onPressed: controller.isCreating.value
                    ? null
                    : controller.createFirstAccount,
              ),
            ],
          )),
    );
  }
}

/// Bottom sheet to pick the shared active month.
void showPeriodPicker() {
  final service = PeriodService.to;
  final year = service.active.value.year.obs;
  Get.bottomSheet(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                KIconButton(
                  icon: LucideIcons.chevronLeft,
                  semanticLabel: 'Tahun sebelumnya',
                  onPressed: () => year.value--,
                ),
                Obx(() => Text('${year.value}',
                    style: AppText.title3.copyWith(color: colorText))),
                KIconButton(
                  icon: LucideIcons.chevronRight,
                  semanticLabel: 'Tahun berikutnya',
                  onPressed: () => year.value++,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(12, (i) {
                return Obx(() {
                  final active = service.active.value;
                  final selected =
                      active.year == year.value && active.month == i + 1;
                  return Material(
                    color: selected ? colorAccent : colorSurface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        service.select(year.value, i + 1);
                        Get.back();
                      },
                      child: Center(
                        child: Text(
                          IdNames.monthShort(i + 1),
                          style: AppText.label.copyWith(
                              color: selected ? colorOnAccent : colorText),
                        ),
                      ),
                    ),
                  );
                });
              }),
            ),
          ],
        ),
      ),
    ),
  );
}
