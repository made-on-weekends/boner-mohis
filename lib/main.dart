import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'background/notification_setup.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/theme/filament_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup background notifications
  await setupNotifications();

  runApp(
    const ProviderScope(
      child: BonerMohisApp(),
    ),
  );
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
