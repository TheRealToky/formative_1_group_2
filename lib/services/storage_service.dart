import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../models/team_member.dart';

class StorageService {
  static const _membersKey = 'members';
  static const _tasksKey = 'tasks';
  static const _currentUserKey = 'currentUserId';

  Future<List<TeamMember>> loadMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_membersKey);
    if (raw == null) {
      final defaults = [
        TeamMember(id: '1', name: 'Alice'),
        TeamMember(id: '2', name: 'Brian'),
      ];
      await saveMembers(defaults);
      return defaults;
    }
    final list = jsonDecode(raw) as List;
    return list.map((m) => TeamMember.fromJson(m)).toList();
  }

  Future<void> saveMembers(List<TeamMember> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _membersKey,
      jsonEncode(members.map((m) => m.toJson()).toList()),
    );
  }

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((t) => Task.fromJson(t)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> setCurrentUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, id);
  }
}
