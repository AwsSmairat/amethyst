import 'package:flutter/material.dart';

import 'package:amethyst/core/theme/app_theme.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/user_dashboard/presentation/pages/user_dashboard_page.dart';

void main() {
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amethyst',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const UserDashboardPage(),
    );
  }
}
