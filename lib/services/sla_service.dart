import '../models/task.dart';

enum SlaStatus { onTrack, atRisk, overdue, completed }

SlaStatus getSlaStatus(Task task) {
  if (task.isCompleted) return SlaStatus.completed;

  final timeLeft = task.deadline.difference(DateTime.now());
  if (timeLeft.isNegative) return SlaStatus.overdue;

  // High priority tasks get a bigger warning window
  final warningHours = task.priority == Priority.high ? 72 : 48;
  if (timeLeft.inHours <= warningHours) return SlaStatus.atRisk;

  return SlaStatus.onTrack;
}
