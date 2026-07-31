import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Centralizes access to the existing encrypted settings box.
class SettingsRepository {
  const SettingsRepository();

  static const String boxName = 'settings';
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _currencyCodeKey = 'currency_code';
  static const String _allowScreenshotsKey = 'allow_screenshots';
  static const String _userNameKey = 'user_name';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  ValueListenable<Box<dynamic>> get listenable => _box.listenable();

  String get currencySymbol =>
      _box.get(_currencySymbolKey, defaultValue: '\$') as String;

  String get currencyCode =>
      _box.get(_currencyCodeKey, defaultValue: 'USD') as String;

  bool get allowScreenshots =>
      _box.get(_allowScreenshotsKey, defaultValue: false) as bool;

  String get userName =>
      _box.get(_userNameKey, defaultValue: 'Friend') as String;

  bool get hasCompletedOnboarding =>
      _box.get(_hasCompletedOnboardingKey, defaultValue: false) as bool;

  Future<void> setCurrency(String symbol, String code) async {
    await _box.putAll({_currencySymbolKey: symbol, _currencyCodeKey: code});
  }

  Future<void> setAllowScreenshots(bool allow) async {
    await _box.put(_allowScreenshotsKey, allow);
  }

  Future<void> setUserName(String name) async {
    await _box.put(_userNameKey, name);
  }

  Future<void> setHasCompletedOnboarding(bool completed) async {
    await _box.put(_hasCompletedOnboardingKey, completed);
  }
}
