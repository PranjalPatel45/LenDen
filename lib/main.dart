import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/app_security_config.dart';
import 'data/expense_repository.dart';
import 'data/security_repository.dart';
import 'data/settings_repository.dart';
import 'model/expense_model.dart';
import 'screen/lock_screen.dart';
import 'screen/splash_screen.dart';
import 'utils/app_colors.dart';
import 'utils/screen_security.dart';

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

  // Apply developer build screen security setting.
  await ScreenSecurity.apply(AppSecurityConfig.allowScreenshots);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({required this.initialization, super.key});

  final Future<void> initialization;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
        if (elapsed.inSeconds >= 30) {
          unawaited(_triggerAutoLock());
        }
      }
    }
  }

  Future<void> _triggerAutoLock() async {
    if (_isLocking) return;
    final hasPin = await securityRepository.hasPin();
    if (!hasPin) return;

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    _isLocking = true;
    await nav.push(
      MaterialPageRoute(
        builder: (context) => const LockScreen(),
      ),
    );
    _isLocking = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LenDen',
      theme: AppColors.theme,
      home: SplashScreen(initialization: widget.initialization),
    );
  }
}

