import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'splash_page.dart';
import 'dashboard_page.dart';
import 'members_page.dart';
import 'sessions_page.dart';
import 'attendance_page.dart';
import 'recap_page.dart';
import 'firebase_options.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF10316B),
      primary: const Color(0xFF10316B),
      secondary: const Color(0xFFFDBE34),
      surface: const Color(0xFFF2F7FF),
    );

    return MaterialApp(
      title: 'Choir Practice Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const SplashPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/members': (context) => const MembersPage(),
        '/sessions': (context) => const SessionsPage(),
        '/attendance': (context) => const AttendancePage(),
        '/recap': (context) => const RecapPage(),
      },
    );
  }
}
