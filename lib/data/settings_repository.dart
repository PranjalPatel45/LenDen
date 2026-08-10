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
  static const String _isBiometricEnabledKey = 'is_biometric_enabled';
  static const String _preferPinOverBiometricKey = 'prefer_pin_over_biometric';

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

  static const String _manualContactsKey = 'manual_contacts';
  static const String _categoriesKey = 'categories';

  static const List<String> defaultCategories = [
    'Food',
    'Shopping',
    'Transport',
    'Bills',
    'Entertainment',
    'Health',
    'Salary',
    'Investment',
    'Other',
  ];

  bool get hasCompletedOnboarding =>
      _box.get(_hasCompletedOnboardingKey, defaultValue: false) as bool;

  List<Map<String, String>> get manualContacts {
    final raw = _box.get(_manualContactsKey, defaultValue: <dynamic>[]) as List;
    return raw.map((item) => Map<String, String>.from(item as Map)).toList();
  }

  Future<void> addManualContact(String name, String? phone) async {
    final current = manualContacts;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    if (!current.any((c) => (c['name'] ?? '').toLowerCase() == trimmedName.toLowerCase())) {
      current.add({'name': trimmedName, 'phone': phone?.trim() ?? ''});
      await _box.put(_manualContactsKey, current);
    }
  }

  List<String> get categories {
    final raw = _box.get(_categoriesKey) as List?;
    if (raw == null || raw.isEmpty) {
      return List<String>.from(defaultCategories);
    }
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> saveCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty) return;
    final current = categories;
    if (!current.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      current.add(trimmed);
      await _box.put(_categoriesKey, current);
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty) return;
    final current = categories;
    current.removeWhere((c) => c.toLowerCase() == trimmed.toLowerCase());
    await _box.put(_categoriesKey, current);
  }

  Future<void> editCategory(String oldName, String newName) async {
    final trimmedOld = oldName.trim();
    final trimmedNew = newName.trim();
    if (trimmedOld.isEmpty || trimmedNew.isEmpty) return;

    final current = categories;
    final index = current.indexWhere(
      (c) => c.toLowerCase() == trimmedOld.toLowerCase(),
    );

    if (index != -1) {
      current[index] = trimmedNew;
      await _box.put(_categoriesKey, current);
    }
  }

  Future<void> resetCategories() async {
    await _box.put(_categoriesKey, List<String>.from(defaultCategories));
  }

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

  bool get isBiometricEnabled =>
      _box.get(_isBiometricEnabledKey, defaultValue: true) as bool;

  bool get preferPinOverBiometric =>
      _box.get(_preferPinOverBiometricKey, defaultValue: false) as bool;

  Future<void> setBiometricEnabled(bool enabled) async {
    await _box.put(_isBiometricEnabledKey, enabled);
    await setPreferPinOverBiometric(false);
  }

  Future<void> setPreferPinOverBiometric(bool prefer) async {
    await _box.put(_preferPinOverBiometricKey, prefer);
  }
}
