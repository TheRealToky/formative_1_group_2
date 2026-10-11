import 'package:flutter/material.dart';
import 'package:sla_tracker/data/data.dart';
import 'package:sla_tracker/screens/dashboard_screen.dart';
import 'package:sla_tracker/screens/task_list_screen.dart';
import 'package:sla_tracker/screens/team_screen.dart';

class MainShell extends StatefulWidget {
  final TeamMember currentUser;
  final int initialIndex;

  const MainShell({
    super.key,
    required this.currentUser,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<TaskListScreenState> _taskListKey = GlobalKey<TaskListScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      if (index == 0) _dashboardKey.currentState?.refresh();
      if (index == 1) _taskListKey.currentState?.refresh();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(key: _dashboardKey, currentUser: widget.currentUser),
      TaskListScreen(key: _taskListKey, currentUser: widget.currentUser),
      TeamScreen(currentUser: widget.currentUser),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _buildNavItem(index: 0, label: 'Dashboard'),
                _buildNavItem(index: 1, label: 'Tasks'),
                _buildNavItem(index: 2, label: 'Team'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required String label}) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2.5,
              width: isSelected ? 36 : 0,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}