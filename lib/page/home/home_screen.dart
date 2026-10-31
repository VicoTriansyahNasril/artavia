import 'package:flutter/material.dart';
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
  static const _tabs = [
    HistoryView(),
    ReportScreen(),
    AccountListView(),
    SettingsView(),
  ];

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
                Obx(() => _TabHeader(
                      index: controller.currentIndex.value,
                      // Nothing to hide before the first account exists.
                      showEye: controller.hasAccounts.value == true,
                    )),
                Expanded(
                  child: Obx(() {
                    final index = controller.currentIndex.value;
                    return IndexedStack(
                      index: index,
                      children: [
                        for (final (i, tab) in _tabs.indexed)
                          _TabFade(active: i == index, child: tab),
                      ],
                    );
                  }),
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

/// Fades a tab in (and lifts it 8 px) each time it becomes the active one,
/// so switching tabs doesn't jump. IndexedStack keeps every tab's state.
class _TabFade extends StatefulWidget {
  final bool active;
  final Widget child;
  const _TabFade({required this.active, required this.child});

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final _slide =
      Tween(begin: const Offset(0, 8), end: Offset.zero).animate(_curve);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      still ? _c.value = 1 : _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
    );
  }
}

/// Per-tab title row; money tabs get the privacy eye, Transaksi also gets
/// Cari and Kalender.
class _TabHeader extends StatelessWidget {
  final int index;
  final bool showEye;
  const _TabHeader({required this.index, required this.showEye});

  @override
  Widget build(BuildContext context) {
    PrivacyService.watch(context);
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
            if (index < 3 && showEye)
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
          if (controller.budgetStep.value) ...[
            const _BudgetStepCard(),
            const SizedBox(height: 12),
          ],
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

/// Greeting and ‹ Oktober 2026 › inside the hero card. Both share one
/// line when the greeting fits in full; otherwise the period moves to a
/// second line so the greeting is never cut off.
class _PeriodRow extends StatelessWidget {
  final String greeting;
  const _PeriodRow({required this.greeting});

  static const _arrows = 44.0 * 2 + 8; // two KIconButtons + gap

  @override
  Widget build(BuildContext context) {
    final greetStyle = AppText.bodySmall.w600.copyWith(color: colorText);
    final labelStyle = AppText.label.copyWith(color: colorText);
    final greet = Text(greeting,
        maxLines: 1, overflow: TextOverflow.ellipsis, style: greetStyle);
    return Obx(() {
      final label = PeriodService.to.active.value.longLabel;
      return LayoutBuilder(builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final need = _textWidth(greeting, greetStyle, scaler) +
            _textWidth(label, labelStyle, scaler) +
            _arrows;
        if (need <= box.maxWidth) {
          return Row(
            children: [
              Expanded(child: greet),
              _nav(label, labelStyle, shrink: false),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            greet,
            Align(
              alignment: Alignment.centerRight,
              child: _nav(label, labelStyle, shrink: true),
            ),
          ],
        );
      });
    });
  }

  static double _textWidth(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// ‹ label ›. With [shrink] the label scales down to the line width
  /// (only possible when the row has a bounded width).
  Widget _nav(String label, TextStyle style, {required bool shrink}) {
    final service = PeriodService.to;
    Widget text = GestureDetector(
      onTap: showPeriodPicker,
      child: Text(label, maxLines: 1, style: style),
    );
    if (shrink) {
      text = Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: text));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KIconButton(
          icon: LucideIcons.chevronLeft,
          size: 18,
          semanticLabel: 'Periode sebelumnya',
          onPressed: () => service.shift(-1),
        ),
        text,
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
    PrivacyService.watch(context);
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
    PrivacyService.watch(context);
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
              KAmountField(
                label: 'Saldo awal',
                value: controller.starterBalance.value,
                onChanged: (n) => controller.starterBalance.value = n,
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

/// Onboarding step 2 (optional): monthly limits for a few expense
/// categories right after the first account. Skippable; full budgets live
/// in Pengaturan › Anggaran.
class _BudgetStepCard extends GetView<HomeController> {
  const _BudgetStepCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        final c = controller;
        final any = c.starterBudgets.values.any((v) => v > 0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: colorAccentDim, shape: BoxShape.circle),
                  child: Icon(LucideIcons.target, color: colorAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Opsional', style: AppText.caption.muted),
                ),
                // Up top so small screens see it without scrolling.
                KButton.text(
                  label: 'Lewati',
                  compact: true,
                  expand: false,
                  onPressed: c.skipBudgetStep,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Atur anggaran bulanan',
                style: AppText.title1.copyWith(color: colorText)),
            const SizedBox(height: 6),
            Text(
                'Batasi pengeluaran untuk kategori yang paling sering '
                'dipakai. Bisa diubah kapan saja di Pengaturan › Anggaran.',
                style: AppText.bodySmall.onGlass),
            const SizedBox(height: 18),
            for (final cat in c.starterCategories) ...[
              KAmountField(
                label: cat['name'] as String,
                value: c.starterBudgets[cat['id']] ?? 0,
                onChanged: (n) => c.starterBudgets[cat['id'] as int] = n,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 6),
            KButton(
              label: 'Simpan anggaran',
              onPressed:
                  !any || c.isCreating.value ? null : c.saveStarterBudgets,
            ),
          ],
        );
      }),
    );
  }
}

/// Bottom sheet to pick the shared active month.
void showPeriodPicker() {
  final service = PeriodService.to;
  final year = service.active.value.year.obs;
  showSheet(
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
