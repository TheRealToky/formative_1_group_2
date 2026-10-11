import 'package:flutter/material.dart';
import 'package:sla_tracker/data/models/enums.dart';

class StatusChip extends StatelessWidget {
  final TaskStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      TaskStatus.todo => ('To do', const Color(0xFFF3F4F6), const Color(0xFF4B5563)),
      TaskStatus.inProgress => ('In progress', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      TaskStatus.done => ('Done', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
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

class SlaStatusChip extends StatelessWidget {
  final SlaStatus status;

  const SlaStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      SlaStatus.onTrack => ('On Track', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      SlaStatus.atRisk => ('At Risk', const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
      SlaStatus.overdue => ('Overdue', const Color(0xFFFEE2E2), const Color(0xFFB91C1C)),
      SlaStatus.completed => ('Completed', const Color(0xFFF1F5F9), const Color(0xFF64748B)),
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
