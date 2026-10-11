import 'package:flutter/material.dart';
import 'package:sla_tracker/data/models/enums.dart';

class PriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const PriorityChip({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (priority) {
      TaskPriority.high => ('High', const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
      TaskPriority.medium => ('Medium', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      TaskPriority.low => ('Low', const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
