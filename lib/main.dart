import 'package:flutter/material.dart';
import 'package:pwa_install/pwa_install.dart';
import 'app_theme.dart';
import 'pages/exhibition_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Widgets binding initialized');

  try {
    PWAInstall().setup();
    print('PWA setup completed');
  } catch (e) {
    print('PWA setup failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ČaV Skener',
      theme: AppTheme.lightTheme,
      home: const ExhibitionListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
