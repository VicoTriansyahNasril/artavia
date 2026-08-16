import 'package:flutter/material.dart';
import 'package:artavia/widgets/commons/common.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TutorialCard extends StatelessWidget {
  final TutorialCoachMarkController controller;
  final String title;
  final String description;
  final bool isLast;

  const TutorialCard({
    super.key,
    required this.controller,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: colorWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: colorWhite.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => controller.skip(),
                child: const Text(
                  "Lewati",
                  style: TextStyle(color: colorGrey),
                ),
              ),
              ElevatedButton(
                onPressed: () => controller.next(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAccent,
                  foregroundColor: colorOnAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isLast ? "Selesai" : "Lanjut"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
