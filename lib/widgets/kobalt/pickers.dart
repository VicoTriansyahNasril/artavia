import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:artavia/widgets/kobalt/k_chip.dart';
import 'package:artavia/widgets/kobalt/k_field.dart';
import 'package:artavia/widgets/kobalt/sheet.dart';

/// The 12 palette colors as round radios. [value] is a canonical (dark)
/// palette value; the swatch shows the active theme's variant.
class PaletteColorPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const PaletteColorPicker(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < categoryPaletteValues.length; i++)
          Semantics(
            button: true,
            selected: categoryPaletteValues[i] == value,
            label: 'Warna ${categoryPaletteNames[i]}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(categoryPaletteValues[i]),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: categoryPalette[i],
                      shape: BoxShape.circle,
                      border: categoryPaletteValues[i] == value
                          ? Border.all(color: colorText, width: 2.5)
                          : null,
                    ),
                    child: categoryPaletteValues[i] == value
                        ? Icon(LucideIcons.check,
                            size: 16, color: colorOnAccent)
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Grid of icons for one group (or a search result), 6 columns.
class IconGrid extends StatelessWidget {
  final List<IconEntry> entries;
  final String? selected;
  final Color color;
  final ValueChanged<String> onSelect;

  const IconGrid({
    super.key,
    required this.entries,
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final e in entries)
          Semantics(
            button: true,
            selected: e.key == selected,
            label: e.label,
            excludeSemantics: true,
            child: Tooltip(
              message: e.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: e.key == selected ? softFill(color) : colorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: e.key == selected
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: Icon(e.icon,
                      size: 22, color: e.key == selected ? color : colorText),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Inline picker: group chips + grid, with "Cari dari 107 ikon". With
/// [entries] it shows just that set as one grid (no groups, no search).
class IconPicker extends StatefulWidget {
  final String? selected;
  final Color color;
  final ValueChanged<String> onSelect;
  final List<IconEntry>? entries;

  const IconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelect,
    this.entries,
  });

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  late String _group = IconRegistry.contains(widget.selected)
      ? IconRegistry.byKey(widget.selected).group
      : IconRegistry.groups.first.id;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    if (entries != null) {
      // Keep an earlier pick from the full set visible and selected.
      final keep = IconRegistry.contains(widget.selected) &&
          !entries.any((e) => e.key == widget.selected);
      return IconGrid(
        entries: [if (keep) IconRegistry.byKey(widget.selected), ...entries],
        selected: widget.selected,
        color: widget.color,
        onSelect: widget.onSelect,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final g in IconRegistry.groups) ...[
                KChip(
                  label: g.label,
                  selected: g.id == _group,
                  onTap: () => setState(() => _group = g.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        IconGrid(
          entries: IconRegistry.inGroup(_group),
          selected: widget.selected,
          color: widget.color,
          onSelect: widget.onSelect,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final key = await showIconSearch(
                  selected: widget.selected, color: widget.color);
              if (key != null) {
                setState(() => _group = IconRegistry.byKey(key).group);
                widget.onSelect(key);
              }
            },
            icon: Icon(LucideIcons.search, size: 16, color: colorAccent),
            label: Text('Cari dari ${IconRegistry.all.length} ikon',
                style: AppText.label.accent),
          ),
        ),
      ],
    );
  }
}

/// Search sheet over all icons (Indonesian labels). Returns the chosen key.
Future<String?> showIconSearch({String? selected, required Color color}) {
  final query = ''.obs;
  return showSheet<String>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 16 + MediaQuery.viewInsetsOf(Get.context!).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(Get.context!).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cari ikon',
                  style: AppText.title3.copyWith(color: colorText)),
              const SizedBox(height: 12),
              KField(
                hint: 'Mis. kopi, bensin, gaji',
                autofocus: true,
                prefix: Icon(LucideIcons.search, size: 18, color: colorGrey),
                onChanged: (v) => query.value = v,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(() {
                    final results = query.value.trim().isEmpty
                        ? IconRegistry.all
                        : IconRegistry.search(query.value);
                    if (results.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Ikon tidak ditemukan',
                            textAlign: TextAlign.center,
                            style: AppText.bodySmall.muted),
                      );
                    }
                    return IconGrid(
                      entries: results,
                      selected: selected,
                      color: color,
                      onSelect: (k) => Get.back(result: k),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
  );
}
