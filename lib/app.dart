import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class LucknowiFashionApp extends StatelessWidget {
  const LucknowiFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lucknowi Fashion POS',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}