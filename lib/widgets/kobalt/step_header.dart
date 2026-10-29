import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';

/// "Langkah 1 dari 3 · Pilih berkas" with a segmented progress bar.
class StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String label;

  const StepHeader(
      {super.key, required this.step, this.total = 3, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Langkah $step dari $total, $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? colorAccent : colorSurface,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text('Langkah $step dari $total · $label',
              style: AppText.caption.muted),
        ],
      ),
    );
  }
}
