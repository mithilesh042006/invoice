import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class SmartShopApp extends StatelessWidget {
  const SmartShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shop Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}
