import 'package:flutter_test/flutter_test.dart';
import 'package:sla_tracker/data/data.dart';

void main() {
  group('SLA Task Status Rules', () {
    final now = DateTime.utc(2026, 10, 11, 12, 0, 0);

    test('Completed tasks are classified as Completed regardless of deadline', () {
      final task = Task(
        projectId: 1,
        title: 'Complete documentation',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        dueAt: now.subtract(const Duration(days: 2)), // deadline passed
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      );

      expect(task.getSlaStatus(now), SlaStatus.completed);
    });

    test('Incomplete tasks with past deadlines are classified as Overdue', () {
      final task = Task(
        projectId: 1,
        title: 'Fix sync bug',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        dueAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      );

      expect(task.getSlaStatus(now), SlaStatus.overdue);
    });

    test('Incomplete tasks within warning window are classified as At Risk (High priority: 72h)', () {
      // High priority task due in 36 hours (<= 72h) -> At Risk
      final highTaskAtRisk = Task(
        projectId: 1,
        title: 'Deploy backend API',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueAt: now.add(const Duration(hours: 36)),
        createdAt: now,
        updatedAt: now,
      );
      expect(highTaskAtRisk.getSlaStatus(now), SlaStatus.atRisk);

      // High priority task due in 80 hours (> 72h) -> On Track
      final highTaskOnTrack = Task(
        projectId: 1,
        title: 'Deploy backend API',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueAt: now.add(const Duration(hours: 80)),
        createdAt: now,
        updatedAt: now,
      );
      expect(highTaskOnTrack.getSlaStatus(now), SlaStatus.onTrack);
    });

    test('Incomplete tasks within warning window are classified as At Risk (Medium priority: 48h)', () {
      // Medium priority task due in 30 hours (<= 48h) -> At Risk
      final medTaskAtRisk = Task(
        projectId: 1,
        title: 'Design screens',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        dueAt: now.add(const Duration(hours: 30)),
        createdAt: now,
        updatedAt: now,
      );
      expect(medTaskAtRisk.getSlaStatus(now), SlaStatus.atRisk);

      // Medium priority task due in 60 hours (> 48h) -> On Track
      final medTaskOnTrack = Task(
        projectId: 1,
        title: 'Design screens',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        dueAt: now.add(const Duration(hours: 60)),
        createdAt: now,
        updatedAt: now,
      );
      expect(medTaskOnTrack.getSlaStatus(now), SlaStatus.onTrack);
    });

    test('Incomplete tasks with comfortable future deadline are classified as On Track', () {
      final task = Task(
        projectId: 1,
        title: 'Future roadmap review',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        dueAt: now.add(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      );

      expect(task.getSlaStatus(now), SlaStatus.onTrack);
    });
  });
}
