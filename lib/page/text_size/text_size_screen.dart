import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/model/transaction_model.dart';
import 'package:artavia/page/text_size/text_size_controller.dart';
import 'package:artavia/widgets/kobalt/kobalt.dart';

/// Ukuran teks (board): system switch, 90–150 % slider, live preview and
/// "Kembalikan ke 100 %".
class TextSizeScreen extends GetView<TextSizeController> {
  const TextSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Ukuran teks',
      body: Obx(() {
        final c = controller;
        const steps = TextSizeController.steps;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            ListGroup(
              children: [
                NavRow(
                  icon: LucideIcons.smartphone,
                  title: 'Ikuti ukuran sistem',
                  subtitle: 'Pakai pengaturan teks di HP',
                  showChevron: false,
                  trailing: KSwitch(
                    value: c.followSystem,
                    semanticLabel: 'Ikuti ukuran sistem',
                    onChanged: c.setFollowSystem,
                  ),
                  onTap: () => c.setFollowSystem(!c.followSystem),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Opacity(
              opacity: c.followSystem ? 0.4 : 1,
              child: IgnorePointer(
                ignoring: c.followSystem,
                child: KCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('A',
                              textScaler: TextScaler.noScaling,
                              style:
                                  AppText.caption.copyWith(color: colorText)),
                          Expanded(
                            child: Slider(
                              value: c.stepIndex.toDouble(),
                              min: 0,
                              max: (steps.length - 1).toDouble(),
                              divisions: steps.length - 1,
                              label: steps[c.stepIndex].label,
                              activeColor: colorAccent,
                              inactiveColor: colorSurfaceSelected,
                              semanticFormatterCallback: (v) =>
                                  steps[v.round()].label,
                              onChanged: (v) => c.setStep(v.round()),
                            ),
                          ),
                          Text('A',
                              textScaler: TextScaler.noScaling,
                              style: AppText.title1.copyWith(color: colorText)),
                        ],
                      ),
                      Text(
                          c.followSystem
                              ? 'Mengikuti sistem'
                              : steps[c.stepIndex].label,
                          style: AppText.label.copyWith(color: colorAccent)),
                    ],
                  ),
                ),
              ),
            ),
            const SectionHeader(title: 'Pratinjau'),
            BalanceHero(
              label: 'Sisa periode ini',
              amount: 3284500,
              figures: [
                HeroFigure(
                    label: 'Pemasukan',
                    amount: 8500000,
                    color: colorIncome,
                    icon: LucideIcons.arrowDownLeft),
                HeroFigure(
                    label: 'Pengeluaran',
                    amount: 5215500,
                    color: colorDanger,
                    icon: LucideIcons.arrowUpRight),
              ],
            ),
            const SizedBox(height: 12),
            ListGroup(
              children: [
                TxRow(
                  tx: TransactionModel(
                    amount: -186000,
                    type: 'pengeluaran',
                    note: 'Belanja bulanan di supermarket dekat rumah',
                    categoryName: 'Belanja',
                    categoryIconKey: 'belanja',
                    categoryColorVal: 0xFFE59A6B,
                    accountName: 'BCA',
                    date: DateTime(2026, 10, 29, 19, 5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            KButton.text(
              label: 'Kembalikan ke 100 %',
              onPressed: c.current == steps[1] ? null : c.reset,
            ),
          ],
        );
      }),
    );
  }
}
