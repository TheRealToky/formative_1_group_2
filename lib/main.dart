import 'package:flutter/material.dart';
import 'package:sla_tracker/data/data.dart';
import 'package:sla_tracker/screens/main_shell.dart';
import 'package:sla_tracker/screens/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.instance.database;
  final currentMember = await AuthRepository(db).currentMember();

  runApp(MyApp(initialMember: currentMember));
}

class MyApp extends StatelessWidget {
  final TeamMember? initialMember;

  const MyApp({super.key, this.initialMember});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskTrack - SLA Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D4ED8),
          primary: const Color(0xFF1D4ED8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: initialMember != null
          ? MainShell(currentUser: initialMember!)
          : const SignInScreen(),
    );
  }
}
