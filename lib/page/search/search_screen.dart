import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/core/utils/currency_format.dart';
import 'package:artavia/core/utils/date_format.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/page/search/search_controller.dart' as app;
import 'package:artavia/widgets/kobalt/kobalt.dart';
import 'package:artavia/widgets/transaction/transaction_item.dart';

/// Cari (board): focused field, filter chips, count + total, day groups
/// with highlighted matches; recent searches and category shortcuts before
/// typing; suggestion and "Cari di semua periode" when nothing matches.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final app.SearchController c = Get.find();
  late final TextEditingController _text =
      TextEditingController(text: c.searchQuery.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(String q) {
    _text.value = TextEditingValue(
        text: q, selection: TextSelection.collapsed(offset: q.length));
    c.useRecent(q);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      leading: ScaffoldLeading.back,
      title: 'Cari',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: KField(
              controller: _text,
              hint: 'Cari catatan, kategori, rekening',
              autofocus: true,
              textInputAction: TextInputAction.search,
              prefix: Icon(LucideIcons.search, size: 18, color: colorGrey),
              suffix: Obx(() => c.hasQuery
                  ? KIconButton(
                      icon: LucideIcons.x,
                      size: 18,
                      semanticLabel: 'Hapus kata kunci',
                      onPressed: () {
                        _text.clear();
                        c.setQuery('');
                      },
                    )
                  : const SizedBox.shrink()),
              onChanged: c.setQuery,
              onSubmitted: (q) => c.useRecent(q),
            ),
          ),
          _Filters(c: c),
          Expanded(
            child: Obx(() {
              c.results.length;
              if (!c.hasQuery) return _Idle(c: c, onPick: _set);
              if (c.isLoading.value && c.results.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.results.isEmpty) return _NoResult(c: c, onPick: _set);
              return _Results(c: c);
            }),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final app.SearchController c;
  const _Filters({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() => _build());
  }

  Widget _build() {
    final account =
        c.accounts.firstWhereOrNull((a) => a['id'] == c.accountId.value);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          KChip(
            label: c.thisPeriodOnly.value ? c.period.label : 'Semua periode',
            icon: LucideIcons.calendar,
            selected: true,
            onTap: () => c.thisPeriodOnly.toggle(),
          ),
          const SizedBox(width: 8),
          for (final t in app.SearchController.typeFilters) ...[
            KChip(
              label: t,
              selected: c.filterType.value == t,
              onTap: () => c.filterType.value = t,
            ),
            const SizedBox(width: 8),
          ],
          KChip(
            label: account?['name'] as String? ?? 'Semua rekening',
            icon: LucideIcons.wallet,
            selected: account != null,
            onTap: () {
              if (account != null) {
                c.accountId.value = null;
                return;
              }
              showAccountPicker(
                accounts: c.accounts,
                selectedId: c.accountId.value,
                onSelect: (id) => c.accountId.value = id,
                title: 'Filter rekening',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final app.SearchController c;
  const _Results({required this.c});

  @override
  Widget build(BuildContext context) {
    final groups = c.byDay.entries.toList();
    final q = c.searchQuery.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
              '${c.results.length} transaksi · total '
              '${CurrencyService.to.money(c.total, signed: true)}',
              style: AppText.label.copyWith(color: colorGrey)),
        ),
        for (final g in groups)
          ListGroup(
            title: '${IdNames.dayLong(g.key)}, ${IdNames.shortDate(g.key)}',
            children: [
              for (final t in g.value) TransactionItem(tx: t, highlight: q),
            ],
          ),
      ],
    );
  }
}

class _Idle extends StatelessWidget {
  final app.SearchController c;
  final ValueChanged<String> onPick;
  const _Idle({required this.c, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (c.recent.isNotEmpty)
              ListGroup(
                title: 'Pencarian terakhir',
                titleAction: KButton.text(
                  label: 'Hapus semua',
                  compact: true,
                  expand: false,
                  onPressed: c.clearRecent,
                ),
                dividerInset: 48,
                children: [
                  for (final r in c.recent)
                    NavRow(
                      leading:
                          Icon(LucideIcons.history, size: 20, color: colorGrey),
                      title: r,
                      onTap: () => onPick(r),
                    ),
                ],
              ),
            if (c.categoryNames.isNotEmpty) ...[
              const SectionHeader(title: 'Cari per kategori'),
              Wrap(
                spacing: 8,
                children: [
                  for (final n in c.categoryNames)
                    KChip(label: n, onTap: () => onPick(n)),
                ],
              ),
            ],
          ],
        ));
  }
}

class _NoResult extends StatelessWidget {
  final app.SearchController c;
  final ValueChanged<String> onPick;
  const _NoResult({required this.c, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final s = c.suggestion.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        EmptyState(
          icon: LucideIcons.searchX,
          title: 'Tidak ada hasil untuk “${c.searchQuery.value.trim()}”',
          body: c.thisPeriodOnly.value
              ? 'Coba kata lain atau cari di semua periode.'
              : 'Coba kata lain.',
          action: Column(
            children: [
              if (s != null)
                KButton.tonal(
                  label: 'Mungkin maksudnya “$s”?',
                  onPressed: () => onPick(s),
                ),
              if (c.thisPeriodOnly.value) ...[
                const SizedBox(height: 8),
                KButton.text(
                  label: 'Cari di semua periode',
                  expand: false,
                  onPressed: c.searchAllPeriods,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
