import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'background/notification_setup.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/theme/filament_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: BonerMohisApp(),
    ),
  );

  // Setup background notifications after first frame — the permission
  // dialog this triggers must never block app startup from completing.
  unawaited(setupNotifications());
}

class BonerMohisApp extends StatelessWidget {
  const BonerMohisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boner Mohis',
      debugShowCheckedModeBanner: false,
      theme: filamentLightTheme(),
      darkTheme: filamentDarkTheme(),
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
