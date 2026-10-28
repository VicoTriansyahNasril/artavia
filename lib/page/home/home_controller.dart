import 'package:flutter/material.dart';
import 'package:artavia/widgets/components/tutorial_card.dart';
import 'package:artavia/page/profile/profile_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/core/database/database_helper.dart';
import 'package:artavia/core/services/period_service.dart';
import 'package:artavia/core/utils/finance_calc.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final transactions = <TransactionModel>[].obs;
  final groupedTransactions = <String, List<TransactionModel>>{}.obs;
  final totalPengeluaran = 0.obs;
  final totalPemasukan = 0.obs;
  final saldoTotal = 0.obs;
  final budget = const BudgetSummary(0, 0, 0).obs;
  final hideBalance = false.obs;
  final currentIndex = 0.obs;

  final GlobalKey keyBottomNavProfile = GlobalKey();

  Period get period => PeriodService.to.active.value;

  void changePage(int index) {
    currentIndex.value = index;
  }

  void toggleHideBalance() {
    hideBalance.value = !hideBalance.value;
  }

  @override
  void onInit() {
    super.onInit();
    ever(PeriodService.to.active, (_) => loadData());
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final p = period;
      final rows =
          await DatabaseHelper.instance.readTransactionsByRange(p.start, p.end);
      final budgets =
          await DatabaseHelper.instance.readBudgetsByMonth(p.year, p.month);

      final loaded = rows.map(TransactionModel.fromDbRow).toList();
      final income = _sum(rows, 'pemasukan');
      final expense = _sum(rows, 'pengeluaran');
      totalPemasukan.value = income;
      totalPengeluaran.value = expense;
      saldoTotal.value = income - expense;
      transactions.value = loaded;
      budget.value = summarizeBudget(budgets, expenseByCategoryId(rows));

      // Group once here instead of in build() to keep scrolling smooth.
      final grouped = <String, List<TransactionModel>>{};
      for (final tx in loaded) {
        if (tx.date == null) continue;
        final key = DateFormat('EEEE, d MMM', 'id_ID').format(tx.date!);
        grouped.putIfAbsent(key, () => []).add(tx);
      }
      groupedTransactions.value = grouped;
    } catch (e) {
      Get.log('Error loading data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int _sum(List<Map<String, dynamic>> rows, String type) => rows
      .where((r) => r['type'] == type)
      .fold(0, (s, r) => s + (r['amount'] as int));

  bool _hasShownTutorial = false;

  Future<void> showTutorialIfNoAccount() async {
    if (_hasShownTutorial) return;
    final accounts = await DatabaseHelper.instance.readAllAccounts();
    if (accounts.isEmpty) {
      _hasShownTutorial = true;
      _showTutorial();
    }
  }

  void _showTutorial() {
    final context = keyBottomNavProfile.currentContext;
    if (context == null) return;
    List<TargetFocus> targets = [
      TargetFocus(
        identify: "TargetProfileTab",
        keyTarget: keyBottomNavProfile,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return TutorialCard(
                controller: controller,
                title: "Mulai Dari Sini!",
                description:
                    "Ketuk menu Saya untuk membuat dompet atau rekening pertama Anda agar bisa mulai mencatat.",
                isLast: true,
              );
            },
          )
        ],
      )
    ];

    void goToProfile() {
      changePage(3);
      Future.delayed(const Duration(milliseconds: 400), () {
        Get.find<ProfileController>().showTutorialIfNoAccount();
      });
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: colorScrim,
      hideSkip: true,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: goToProfile,
      onClickTarget: (_) => goToProfile(),
    ).show(context: context);
  }
}
