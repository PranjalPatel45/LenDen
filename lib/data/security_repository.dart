import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Owns all secure-storage keys used by the application.
class SecurityRepository {
  const SecurityRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _hiveEncryptionKey = 'hive_encryption_key';
  static const String _appPinKey = 'app_pin';
  static const String _pinBackupKey = 'security_pin_backup';
  static const String _settingsBoxName = 'settings';
  static const String _pinAttemptStateKey = 'pin_attempt_state';
  static const String _recoveryQuestionsKey = 'recovery_questions';
  static const String _recoveryAttemptStateKey = 'recovery_attempt_state';
  static const int _pinCredentialVersion = 1;

  static const List<String> recoveryQuestionChoices = [
    'What was your childhood nickname?',
    'In which city were you born?',
    'What was the name of your first school?',
    'What was the name of your first pet?',
    'What was your favorite teacher’s name?',
    'What is the name of your favorite childhood place?',
  ];

  final FlutterSecureStorage _storage;

  Future<List<int>> getOrCreateHiveEncryptionKey() async {
    var storedKey = await _storage.read(key: _hiveEncryptionKey);
    if (storedKey == null) {
      storedKey = base64Url.encode(Hive.generateSecureKey());
      await _storage.write(key: _hiveEncryptionKey, value: storedKey);
    }

    final decoded = base64Url.decode(storedKey);
    if (decoded.length != 32) {
      throw const FormatException('Invalid Hive encryption key length.');
    }
    return decoded;
  }

  Future<bool> hasPin() async => await _readPinCredential() != null;

  Future<bool> verifyPin(String pin) async {
    final credential = await _readPinCredential();
    if (credential == null) return false;
    final candidateHash = _hashPin(pin, credential.salt);
    return _constantTimeEquals(candidateHash, credential.hash);
  }

  Future<void> savePin(String pin) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('PIN must contain exactly four digits.');
    }
    final salt = _newSalt();
    final credential = _PinCredential(
      version: _pinCredentialVersion,
      salt: salt,
      hash: _hashPin(pin, salt),
    );
    await _writePinCredential(credential);
    await _storage.delete(key: _pinAttemptStateKey);
  }

  Future<void> removePin() async {
    await _storage.delete(key: _appPinKey);
    if (Hive.isBoxOpen(_settingsBoxName)) {
      final box = Hive.box<dynamic>(_settingsBoxName);
      await box.delete(_pinBackupKey);
      await box.delete('is_biometric_enabled');
      await box.delete('prefer_pin_over_biometric');
    }
    await _storage.delete(key: _pinAttemptStateKey);
    await _storage.delete(key: _recoveryQuestionsKey);
    await _storage.delete(key: _recoveryAttemptStateKey);
  }

  Future<_PinCredential?> _readPinCredential() async {
    var stored = await _storage.read(key: _appPinKey);
    if (stored == null) {
      stored = _readPinBackup();
      if (stored != null) {
        await _storage.write(key: _appPinKey, value: stored);
      }
    } else {
      await _writePinBackup(stored);
    }
    if (stored == null) return null;

    final credential = _PinCredential.tryParse(stored);
    if (credential != null) return credential;

    // One-time, transparent migration from releases that stored a raw PIN.
    // Only the exact legacy four-digit format is accepted; damaged data is
    // never treated as an authentication secret.
    if (RegExp(r'^\d{4}$').hasMatch(stored)) {
      final salt = _newSalt();
      final migrated = _PinCredential(
        version: _pinCredentialVersion,
        salt: salt,
        hash: _hashPin(stored, salt),
      );
      await _writePinCredential(migrated);
      return migrated;
    }
    return null;
  }

  Future<void> _writePinCredential(_PinCredential credential) async {
    final encoded = jsonEncode(credential.toJson());
    await _storage.write(key: _appPinKey, value: encoded);
    await _writePinBackup(encoded);
  }

  String? _readPinBackup() {
    if (!Hive.isBoxOpen(_settingsBoxName)) return null;
    final value = Hive.box<dynamic>(_settingsBoxName).get(_pinBackupKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  Future<void> _writePinBackup(String credential) async {
    if (!Hive.isBoxOpen(_settingsBoxName)) return;
    await Hive.box<dynamic>(_settingsBoxName).put(_pinBackupKey, credential);
  }

  Future<void> savePinAndRecovery({
    required String pin,
    required String questionOne,
    required String answerOne,
    required String questionTwo,
    required String answerTwo,
  }) async {
    await saveRecoveryQuestions(
      questionOne: questionOne,
      answerOne: answerOne,
      questionTwo: questionTwo,
      answerTwo: answerTwo,
    );
    await savePin(pin);
  }

  Future<void> saveRecoveryQuestions({
    required String questionOne,
    required String answerOne,
    required String questionTwo,
    required String answerTwo,
  }) async {
    if (questionOne == questionTwo) {
      throw const FormatException('Recovery questions must be different.');
    }
    if (_normalizeAnswer(answerOne).isEmpty ||
        _normalizeAnswer(answerTwo).isEmpty) {
      throw const FormatException('Recovery answers cannot be empty.');
    }

    final firstSalt = _newSalt();
    final secondSalt = _newSalt();
    final setup = RecoveryQuestionSetup(
      questionOne: questionOne,
      questionTwo: questionTwo,
      firstSalt: firstSalt,
      firstAnswerHash: _hashAnswer(answerOne, firstSalt),
      secondSalt: secondSalt,
      secondAnswerHash: _hashAnswer(answerTwo, secondSalt),
    );
    await _storage.write(
      key: _recoveryQuestionsKey,
      value: jsonEncode(setup.toJson()),
    );
    await _storage.delete(key: _recoveryAttemptStateKey);
  }

  Future<RecoveryQuestionSetup?> readRecoveryQuestions() async {
    final stored = await _storage.read(key: _recoveryQuestionsKey);
    if (stored == null) return null;
    try {
      return RecoveryQuestionSetup.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<bool> verifyRecoveryAnswers({
    required String answerOne,
    required String answerTwo,
  }) async {
    final setup = await readRecoveryQuestions();
    if (setup == null) return false;
    final first = _hashAnswer(answerOne, setup.firstSalt);
    final second = _hashAnswer(answerTwo, setup.secondSalt);
    return _constantTimeEquals(first, setup.firstAnswerHash) &&
        _constantTimeEquals(second, setup.secondAnswerHash);
  }

  Future<RecoveryAttemptState> readRecoveryAttemptState({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final stored = await _storage.read(key: _recoveryAttemptStateKey);
    var state = RecoveryAttemptState.fresh(currentTime);
    if (stored != null) {
      try {
        state = RecoveryAttemptState.fromJson(
          jsonDecode(stored) as Map<String, dynamic>,
        ).normalized(currentTime);
      } on FormatException {
        // Damaged attempt metadata is replaced below.
      } on TypeError {
        // Damaged attempt metadata is replaced below.
      }
    }
    await _writeRecoveryAttemptState(state);
    return state;
  }

  Future<RecoveryAttemptState> recordFailedRecoveryAttempt({
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final current = await readRecoveryAttemptState(now: currentTime);
    final updated = current.afterFailure(currentTime);
    await _writeRecoveryAttemptState(updated);
    return updated;
  }

  Future<void> resetRecoveryAttempts() =>
      _storage.delete(key: _recoveryAttemptStateKey);

  Future<void> _writeRecoveryAttemptState(RecoveryAttemptState state) =>
      _storage.write(
        key: _recoveryAttemptStateKey,
        value: jsonEncode(state.toJson()),
      );

  static String _normalizeAnswer(String answer) =>
      answer.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  static String _hashAnswer(String answer, String salt) => sha256
      .convert(utf8.encode('$salt:${_normalizeAnswer(answer)}'))
      .toString();

  static String _hashPin(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool _constantTimeEquals(String first, String second) {
    if (first.length != second.length) return false;
    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }

  Future<PinAttemptState> readPinAttemptState({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final stored = await _storage.read(key: _pinAttemptStateKey);
    var state = PinAttemptState.fresh(currentTime);
    if (stored != null) {
      try {
        state = PinAttemptState.fromJson(
          jsonDecode(stored) as Map<String, dynamic>,
        ).normalized(currentTime);
      } on FormatException {
        // Replace damaged attempt metadata with a valid state. The PIN itself
        // remains protected by its separate secure-storage entry.
      } on TypeError {
        // JSON with unexpected field types is treated as damaged metadata.
      }
    }
    await _writePinAttemptState(state);
    return state;
  }

  Future<PinAttemptState> recordFailedPinAttempt({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final current = await readPinAttemptState(now: currentTime);
    final updated = current.afterFailure(currentTime);
    await _writePinAttemptState(updated);
    return updated;
  }

  Future<PinAttemptState> recordSuccessfulPin({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final current = await readPinAttemptState(now: currentTime);
    final updated = current.afterSuccess(currentTime);
    await _writePinAttemptState(updated);
    return updated;
  }

  Future<void> _writePinAttemptState(PinAttemptState state) => _storage.write(
    key: _pinAttemptStateKey,
    value: jsonEncode(state.toJson()),
  );
}

class _PinCredential {
  const _PinCredential({
    required this.version,
    required this.salt,
    required this.hash,
  });

  final int version;
  final String salt;
  final String hash;

  static _PinCredential? tryParse(String value) {
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final version = json['version'] as int;
      final salt = json['salt'] as String;
      final hash = json['hash'] as String;
      if (version != SecurityRepository._pinCredentialVersion ||
          salt.isEmpty ||
          hash.length != 64) {
        return null;
      }
      return _PinCredential(version: version, salt: salt, hash: hash);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Map<String, Object> toJson() => {
    'version': version,
    'salt': salt,
    'hash': hash,
  };
}

class RecoveryQuestionSetup {
  const RecoveryQuestionSetup({
    required this.questionOne,
    required this.questionTwo,
    required this.firstSalt,
    required this.firstAnswerHash,
    required this.secondSalt,
    required this.secondAnswerHash,
  });

  final String questionOne;
  final String questionTwo;
  final String firstSalt;
  final String firstAnswerHash;
  final String secondSalt;
  final String secondAnswerHash;

  factory RecoveryQuestionSetup.fromJson(Map<String, dynamic> json) =>
      RecoveryQuestionSetup(
        questionOne: json['questionOne'] as String,
        questionTwo: json['questionTwo'] as String,
        firstSalt: json['firstSalt'] as String,
        firstAnswerHash: json['firstAnswerHash'] as String,
        secondSalt: json['secondSalt'] as String,
        secondAnswerHash: json['secondAnswerHash'] as String,
      );

  Map<String, String> toJson() => {
    'questionOne': questionOne,
    'questionTwo': questionTwo,
    'firstSalt': firstSalt,
    'firstAnswerHash': firstAnswerHash,
    'secondSalt': secondSalt,
    'secondAnswerHash': secondAnswerHash,
  };
}

class RecoveryAttemptState {
  const RecoveryAttemptState({
    required this.day,
    required this.failedToday,
    required this.failedInCurrentGroup,
    this.cooldownUntil,
  });

  static const int attemptsPerCooldown = 3;
  static const int maximumAttemptsPerDay = 10;
  static const Duration cooldownDuration = Duration(seconds: 30);

  final String day;
  final int failedToday;
  final int failedInCurrentGroup;
  final DateTime? cooldownUntil;

  factory RecoveryAttemptState.fresh(DateTime now) => RecoveryAttemptState(
    day: _formatDayKey(now),
    failedToday: 0,
    failedInCurrentGroup: 0,
  );

  factory RecoveryAttemptState.fromJson(Map<String, dynamic> json) {
    final cooldownValue = json['cooldownUntil'] as String?;
    return RecoveryAttemptState(
      day: json['day'] as String? ?? '',
      failedToday: json['failedToday'] as int? ?? 0,
      failedInCurrentGroup: json['failedInCurrentGroup'] as int? ?? 0,
      cooldownUntil: cooldownValue == null
          ? null
          : DateTime.tryParse(cooldownValue)?.toLocal(),
    );
  }

  bool get isDailyLocked => failedToday >= maximumAttemptsPerDay;

  int get attemptsRemainingToday =>
      (maximumAttemptsPerDay - failedToday).clamp(0, maximumAttemptsPerDay);

  DateTime lockedUntil(DateTime now) {
    if (isDailyLocked) {
      final parts = day.split('-').map(int.parse).toList(growable: false);
      return DateTime(parts[0], parts[1], parts[2] + 1);
    }
    return cooldownUntil ?? now;
  }

  bool isLockedAt(DateTime now) => lockedUntil(now).isAfter(now);

  RecoveryAttemptState normalized(DateTime now) {
    if (day != _formatDayKey(now)) return RecoveryAttemptState.fresh(now);
    if (cooldownUntil != null && !cooldownUntil!.isAfter(now)) {
      return RecoveryAttemptState(
        day: day,
        failedToday: failedToday,
        failedInCurrentGroup: failedInCurrentGroup,
      );
    }
    return this;
  }

  RecoveryAttemptState afterFailure(DateTime now) {
    final current = normalized(now);
    if (current.isLockedAt(now)) return current;
    final dailyFailures = current.failedToday + 1;
    if (dailyFailures >= maximumAttemptsPerDay) {
      return RecoveryAttemptState(
        day: current.day,
        failedToday: maximumAttemptsPerDay,
        failedInCurrentGroup: 0,
      );
    }
    final groupFailures = current.failedInCurrentGroup + 1;
    final startsCooldown = groupFailures >= attemptsPerCooldown;
    return RecoveryAttemptState(
      day: current.day,
      failedToday: dailyFailures,
      failedInCurrentGroup: startsCooldown ? 0 : groupFailures,
      cooldownUntil: startsCooldown ? now.add(cooldownDuration) : null,
    );
  }

  Map<String, Object?> toJson() => {
    'day': day,
    'failedToday': failedToday,
    'failedInCurrentGroup': failedInCurrentGroup,
    'cooldownUntil': cooldownUntil?.toUtc().toIso8601String(),
  };
}

class PinAttemptState {
  const PinAttemptState({
    required this.day,
    required this.failedToday,
    required this.failedInCurrentGroup,
    this.cooldownUntil,
  });

  static const int attemptsPerCooldown = 3;
  static const int maximumAttemptsPerDay = 15;
  static const Duration cooldownDuration = Duration(seconds: 30);

  final String day;
  final int failedToday;
  final int failedInCurrentGroup;
  final DateTime? cooldownUntil;

  factory PinAttemptState.fresh(DateTime now) => PinAttemptState(
    day: _formatDayKey(now),
    failedToday: 0,
    failedInCurrentGroup: 0,
  );

  factory PinAttemptState.fromJson(Map<String, dynamic> json) {
    final cooldownValue = json['cooldownUntil'] as String?;
    return PinAttemptState(
      day: json['day'] as String? ?? '',
      failedToday: json['failedToday'] as int? ?? 0,
      failedInCurrentGroup: json['failedInCurrentGroup'] as int? ?? 0,
      cooldownUntil: cooldownValue == null
          ? null
          : DateTime.tryParse(cooldownValue)?.toLocal(),
    );
  }

  bool get isDailyLocked => failedToday >= maximumAttemptsPerDay;

  int get attemptsRemainingToday =>
      (maximumAttemptsPerDay - failedToday).clamp(0, maximumAttemptsPerDay);

  DateTime lockedUntil(DateTime now) {
    if (isDailyLocked) {
      final parts = day.split('-').map(int.parse).toList(growable: false);
      return DateTime(parts[0], parts[1], parts[2] + 1);
    }
    return cooldownUntil ?? now;
  }

  bool isLockedAt(DateTime now) => lockedUntil(now).isAfter(now);

  PinAttemptState normalized(DateTime now) {
    if (day != _formatDayKey(now)) return PinAttemptState.fresh(now);
    if (cooldownUntil != null && !cooldownUntil!.isAfter(now)) {
      return PinAttemptState(
        day: day,
        failedToday: failedToday,
        failedInCurrentGroup: failedInCurrentGroup,
      );
    }
    return this;
  }

  PinAttemptState afterFailure(DateTime now) {
    final current = normalized(now);
    if (current.isLockedAt(now)) return current;

    final dailyFailures = current.failedToday + 1;
    if (dailyFailures >= maximumAttemptsPerDay) {
      return PinAttemptState(
        day: current.day,
        failedToday: maximumAttemptsPerDay,
        failedInCurrentGroup: 0,
      );
    }

    final groupFailures = current.failedInCurrentGroup + 1;
    final startsCooldown = groupFailures >= attemptsPerCooldown;
    return PinAttemptState(
      day: current.day,
      failedToday: dailyFailures,
      failedInCurrentGroup: startsCooldown ? 0 : groupFailures,
      cooldownUntil: startsCooldown ? now.add(cooldownDuration) : null,
    );
  }

  PinAttemptState afterSuccess(DateTime now) {
    final current = normalized(now);
    return PinAttemptState(
      day: current.day,
      failedToday: current.failedToday,
      failedInCurrentGroup: 0,
    );
  }

  Map<String, Object?> toJson() => {
    'day': day,
    'failedToday': failedToday,
    'failedInCurrentGroup': failedInCurrentGroup,
    'cooldownUntil': cooldownUntil?.toUtc().toIso8601String(),
  };
}

String _formatDayKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
