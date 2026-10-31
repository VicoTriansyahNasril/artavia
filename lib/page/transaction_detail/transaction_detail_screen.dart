import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/database/transaction_store.dart';
import 'package:artavia/core/models/recurring_rule.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/data_refresh.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/page/recurring/recurring_controller.dart';
import 'package:artavia/widgets/components/app_feedback.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';

/// Detail transaksi (board): big icon and amount, type pill, Rincian,
/// category budget, Jadikan berulang, Duplikat ke hari ini, Hapus (undo).
/// Arguments come from [transactionArgs].
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Map<String, dynamic>.from(Get.arguments ?? {});
    final type = arg['type'] as String? ?? 'pengeluaran';
    final isTransfer = type == 'transfer';
    final isIncome = type == 'pemasukan';
    final amount = arg['amount'] as int? ?? 0;
    final note = (arg['note'] as String? ?? '').trim();
    final date = arg['date'] as DateTime? ?? DateTime.now();
    final category = isTransfer
        ? 'Transfer'
        : (arg['category'] as String? ?? 'Tanpa kategori');
    final title = note.isNotEmpty ? note : category;
    final color = isTransfer
        ? colorAccent
        : themedColor(arg['color_val'] as int?, fallbackIndex: 11);
    final (typeLabel, typeTone) = switch (type) {
      'pemasukan' => ('Pemasukan', colorIncome),
      'transfer' => ('Transfer', colorAccent),
      _ => ('Pengeluaran', colorDanger),
    };
    final money = CurrencyService.to;
    final adminFee = arg['admin_fee'] as int? ?? 0;

    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Detail transaksi',
      actions: [
        KIconButton(
          icon: LucideIcons.pencil,
          semanticLabel: 'Ubah transaksi',
          onPressed: () => openTransactionEditor(arg),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: CategoryIcon.round(
              iconKey: arg['icon_key'] as String?,
              iconPath: arg['icon_path'] as String?,
              iconCode: arg['icon_code'] as int?,
              color: color,
              diameter: 64,
            ),
          ),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: AppText.title3.copyWith(color: colorText)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isTransfer
                  ? money.money(amount)
                  : money.money(isIncome ? amount : -amount, signed: true),
              style: AppText.amountXL
                  .copyWith(color: isIncome ? colorIncome : colorText),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: softFill(typeTone),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(typeLabel,
                  style: AppText.label.copyWith(color: typeTone)),
            ),
          ),
          const SizedBox(height: 8),
          ListGroup(
            title: 'Rincian',
            dividerInset: 14,
            children: [
              if (isTransfer) ...[
                _row('Dari', arg['account'] as String? ?? '—'),
                _row('Ke', arg['destination_account'] as String? ?? '—'),
                if (adminFee > 0) _row('Biaya admin', money.money(adminFee)),
              ] else ...[
                _row('Kategori', category),
                _row('Rekening', arg['account'] as String? ?? '—'),
              ],
              _row('Tanggal',
                  DateFormat("d MMMM yyyy '·' HH.mm", 'id_ID').format(date)),
              _row('Catatan', note.isEmpty ? '—' : note),
            ],
          ),
          if (type == 'pengeluaran' && arg['category_id'] != null)
            _CategoryBudget(
              categoryId: arg['category_id'] as int,
              date: date,
            ),
          const SizedBox(height: 8),
          ListGroup(
            title: 'Aksi',
            children: [
              if (!isTransfer && arg['category_id'] != null)
                NavRow(
                  icon: LucideIcons.repeat,
                  title: 'Jadikan transaksi berulang',
                  subtitle: 'Dicatat otomatis setiap bulan',
                  onTap: () => _makeRecurring(arg),
                ),
              NavRow(
                icon: LucideIcons.copy,
                title: 'Duplikat ke hari ini',
                subtitle: 'Salin dengan tanggal hari ini',
                onTap: () => _duplicate(arg['id'] as int?),
              ),
            ],
          ),
          const SizedBox(height: 20),
          KButton.danger(
            label: 'Hapus transaksi',
            icon: LucideIcons.trash2,
            onPressed: () async {
              final ok = await deleteTransactionWithUndo(arg['id'] as int?,
                  label: title);
              if (ok) Get.back();
            },
          ),
        ],
      ),
    );
  }

  static Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              child: Text(label, style: AppText.bodySmall.muted),
            ),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: AppText.bodySmall.copyWith(color: colorText)),
            ),
          ],
        ),
      );

  Future<void> _duplicate(int? id) async {
    if (id == null) return;
    final newId = await DatabaseHelper.instance.duplicateToToday(id);
    if (newId == null) return;
    refreshAllGlobalData();
    Get.back();
    AppToast.success('Diduplikat', 'Salinan dicatat hari ini');
  }

  Future<void> _makeRecurring(Map<String, dynamic> arg) async {
    if (!Get.isRegistered<RecurringController>()) {
      Get.put(RecurringController());
    }
    await Get.find<RecurringController>().openForm(RecurringRule(
      type: arg['type'] as String,
      amount: arg['amount'] as int? ?? 0,
      categoryId: arg['category_id'] as int,
      accountId: arg['account_id'] as int,
      note: arg['note'] as String? ?? '',
      frequency: RecurringFrequency.monthly,
      startDate: DateTime.now(),
    ));
  }
}

/// "Anggaran <nama>" card: the budget holding this category in the period
/// the transaction falls in.
class _CategoryBudget extends StatelessWidget {
  final int categoryId;
  final DateTime date;

  const _CategoryBudget({required this.categoryId, required this.date});

  Future<(String, int, int)?> _load() async {
    final db = DatabaseHelper.instance;
    final period = Period.containing(date, PeriodService.to.startDay);
    final budgets = await db.readBudgetsByMonth(period.year, period.month);
    final budget = budgetOfCategory(budgets, categoryId);
    if (budget == null) return null;
    final rows = await db.readTransactionsByRange(period.start, period.end);
    final used = budgetUsed(budget, expenseByCategoryId(rows));
    return (
      budget['name'] as String,
      used,
      budget['budget_amount'] as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String, int, int)?>(
      future: _load(),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final (name, used, limit) = data;
        final level = budgetStatus(used, limit);
        final tone = switch (level) {
          BudgetLevel.over => KTone.danger,
          BudgetLevel.near => KTone.warning,
          BudgetLevel.safe => KTone.accent,
        };
        final money = CurrencyService.to;
        final left = limit - used;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Anggaran $name'),
            KCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${money.money(used)} dari ${money.money(limit)}',
                      style: AppText.bodySmall.w600.copyWith(color: colorText)),
                  const SizedBox(height: 10),
                  KProgress(value: limit == 0 ? 1 : used / limit, tone: tone),
                  const SizedBox(height: 8),
                  Text(
                    left >= 0
                        ? 'Sisa ${money.money(left)}'
                        : 'Lewat ${money.money(-left)}',
                    style: AppText.caption
                        .copyWith(color: left >= 0 ? colorGrey : colorDanger),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
