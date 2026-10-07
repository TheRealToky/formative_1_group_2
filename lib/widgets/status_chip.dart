import 'package:flutter/material.dart';
import 'package:sla_tracker/services/sla_service.dart';

class StatusChip extends StatelessWidget {
  final SlaStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SlaStatus.onTrack => ('On Track', Colors.green),
      SlaStatus.atRisk => ('At Risk', Colors.orange),
      SlaStatus.overdue => ('Overdue', Colors.red),
      SlaStatus.completed => ('Completed', Colors.grey),
    };
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
