import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Centralizes access to the existing encrypted settings box.
class SettingsRepository {
  const SettingsRepository();

  static const String boxName = 'settings';
  static const String _currencySymbolKey = 'currency_symbol';
  static const String _currencyCodeKey = 'currency_code';
  static const String _allowScreenshotsKey = 'allow_screenshots';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  ValueListenable<Box<dynamic>> get listenable => _box.listenable();

  String get currencySymbol =>
      _box.get(_currencySymbolKey, defaultValue: '\$') as String;

  String get currencyCode =>
      _box.get(_currencyCodeKey, defaultValue: 'USD') as String;

  bool get allowScreenshots =>
      _box.get(_allowScreenshotsKey, defaultValue: false) as bool;

  Future<void> setCurrency(String symbol, String code) async {
    await _box.putAll({_currencySymbolKey: symbol, _currencyCodeKey: code});
  }

  Future<void> setAllowScreenshots(bool allow) async {
    await _box.put(_allowScreenshotsKey, allow);
  }
}
