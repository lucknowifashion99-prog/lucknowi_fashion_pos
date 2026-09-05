import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'providers/staff_provider.dart';
import 'theme/app_theme.dart';

class LucknowiFashionApp extends StatelessWidget {
  const LucknowiFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Lucknowi Fashion POS',

      theme: AppTheme.lightTheme,

      home: const _AppStartScreen(),
    );
  }
}

// =============================================================
// APP START SCREEN
// =============================================================

class _AppStartScreen extends StatelessWidget {
  const _AppStartScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (
          context,
          staffProvider,
          child,
          ) {
        // =======================================================
        // LOGGED IN
        // =======================================================

        if (staffProvider.isLoggedIn) {
          return const DashboardScreen();
        }

        // =======================================================
        // NOT LOGGED IN
        // =======================================================

        return const LoginScreen();
      },
    );
  }
}