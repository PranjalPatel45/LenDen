import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do/data/expense_repository.dart';
import 'package:to_do/data/security_repository.dart';
import 'package:to_do/data/settings_repository.dart';
import 'package:to_do/screen/splash_screen.dart';
import 'package:to_do/utils/app_colors.dart';

import 'model/expense_model.dart';

const SecurityRepository securityRepository = SecurityRepository();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw the Flutter splash immediately. App initialization continues while
  // the splash animation is visible instead of keeping the native launch
  // window (and its launcher icon) on screen.
  final initialization = _initializeApp();
  runApp(MyApp(initialization: initialization));
}

Future<void> _initializeApp() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());

  // Open boxes with AES-256 encryption.
  final encryptionKey = await securityRepository.getOrCreateHiveEncryptionKey();
  await Hive.openBox<Expense>(
    ExpenseRepository.boxName,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
  await Hive.openBox(
    SettingsRepository.boxName,
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.initialization, super.key});

  final Future<void> initialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LenDen',
      theme: AppColors.theme,
      home: SplashScreen(initialization: initialization),
    );
  }
}
