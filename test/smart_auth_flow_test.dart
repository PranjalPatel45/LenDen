import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:to_do/data/security_repository.dart';
import 'package:to_do/data/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<dynamic> settingsBox;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('smart_auth_test');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox<dynamic>(SettingsRepository.boxName);
  });

  tearDown(() async {
    await settingsBox.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('Smart Authentication Preferences & Flow', () {
    test('default biometric settings are enabled and do not prefer PIN initially', () async {
      const settingsRepo = SettingsRepository();
      expect(settingsRepo.isBiometricEnabled, isTrue);
      expect(settingsRepo.preferPinOverBiometric, isFalse);
    });

    test('setting preferPinOverBiometric updates preference locally', () async {
      const settingsRepo = SettingsRepository();
      await settingsRepo.setPreferPinOverBiometric(true);
      expect(settingsRepo.preferPinOverBiometric, isTrue);
    });

    test('toggling biometric option off and on resets preferred unlock method', () async {
      const settingsRepo = SettingsRepository();
      await settingsRepo.setPreferPinOverBiometric(true);
      expect(settingsRepo.preferPinOverBiometric, isTrue);

      // Disable biometrics
      await settingsRepo.setBiometricEnabled(false);
      expect(settingsRepo.isBiometricEnabled, isFalse);
      expect(settingsRepo.preferPinOverBiometric, isFalse);

      // Re-enable biometrics
      await settingsRepo.setBiometricEnabled(true);
      expect(settingsRepo.isBiometricEnabled, isTrue);
      expect(settingsRepo.preferPinOverBiometric, isFalse);
    });

    test('removing PIN clears biometric preferences from Hive storage', () async {
      const securityRepo = SecurityRepository();
      const settingsRepo = SettingsRepository();

      await securityRepo.savePin('1234');
      await settingsRepo.setPreferPinOverBiometric(true);
      expect(settingsRepo.preferPinOverBiometric, isTrue);

      await securityRepo.removePin();
      expect(settingsBox.containsKey('is_biometric_enabled'), isFalse);
      expect(settingsBox.containsKey('prefer_pin_over_biometric'), isFalse);
      expect(settingsRepo.isBiometricEnabled, isTrue);
      expect(settingsRepo.preferPinOverBiometric, isFalse);
    });
  });
}
