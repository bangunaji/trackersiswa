import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'services/database_helper.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale bahasa Indonesia untuk format tanggal
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Error init locale: $e');
  }

  // Inisialisasi awal database SQLite
  await DatabaseHelper.instance.database;

  runApp(const SmandaApp());
}

class SmandaApp extends StatelessWidget {
  const SmandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMANDA Activity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
