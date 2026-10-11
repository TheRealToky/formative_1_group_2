const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String formatDateShort(DateTime? d) {
  if (d == null) return 'No date';
  final local = d.toLocal();
  return '${_months[local.month - 1]} ${local.day}';
}

String formatDateFull(DateTime? d) {
  if (d == null) return 'No deadline';
  final local = d.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

String formatOverdue(DateTime due, [DateTime? relativeTo]) {
  final now = relativeTo ?? DateTime.now();
  final diff = now.difference(due);
  if (diff.isNegative) return '';
  if (diff.inDays >= 1) {
    return 'Overdue ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"}';
  } else if (diff.inHours >= 1) {
    return 'Overdue ${diff.inHours}h';
  } else {
    return 'Overdue ${diff.inMinutes}m';
  }
}

String formatSlaRemaining(DateTime sla, [DateTime? relativeTo]) {
  final now = relativeTo ?? DateTime.now();
  final diff = sla.difference(now);
  if (diff.isNegative) {
    return 'SLA breached';
  }
  if (diff.inDays >= 1) {
    return 'SLA ${diff.inDays}d left';
  } else if (diff.inHours >= 1) {
    return 'SLA ${diff.inHours}h left';
  } else {
    return 'SLA ${diff.inMinutes}m left';
  }
}

String formatDate(DateTime d) {
  return formatDateShort(d);
}
