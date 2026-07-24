import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:to_do/data/security_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('recovery answers are normalized, hashed, and verified', () async {
    const repository = SecurityRepository();
    await repository.saveRecoveryQuestions(
      questionOne: SecurityRepository.recoveryQuestionChoices[0],
      answerOne: '  Blue   Bird ',
      questionTwo: SecurityRepository.recoveryQuestionChoices[1],
      answerTwo: 'Mumbai',
    );

    expect(
      await repository.verifyRecoveryAnswers(
        answerOne: 'blue bird',
        answerTwo: ' MUMBAI ',
      ),
      isTrue,
    );
    expect(
      await repository.verifyRecoveryAnswers(
        answerOne: 'wrong',
        answerTwo: 'Mumbai',
      ),
      isFalse,
    );

    final stored = await const FlutterSecureStorage().readAll();
    expect(stored.values.join(), isNot(contains('Blue Bird')));
    expect(stored.values.join(), isNot(contains('Mumbai')));
  });

  test('PIN is restored when its secure-storage entry is missing', () async {
    final directory = await Directory.systemTemp.createTemp('pin_backup_test');
    Hive.init(directory.path);
    final settingsBox = await Hive.openBox<dynamic>('settings');

    try {
      const repository = SecurityRepository();
      await repository.savePin('2468');

      final initiallyStored = await const FlutterSecureStorage().read(
        key: 'app_pin',
      );
      expect(initiallyStored, isNotNull);
      expect(initiallyStored, isNot(contains('2468')));
      final backup = settingsBox.get('security_pin_backup') as String?;
      expect(backup, isNotNull);
      expect(backup, isNot(contains('2468')));
      expect(await repository.verifyPin('2468'), isTrue);
      expect(await repository.verifyPin('1357'), isFalse);

      FlutterSecureStorage.setMockInitialValues({});

      expect(await repository.hasPin(), isTrue);
      expect(await repository.verifyPin('2468'), isTrue);
      final restoredCredential = await const FlutterSecureStorage().read(
        key: 'app_pin',
      );
      expect(restoredCredential, isNotNull);
      expect(restoredCredential, isNot(contains('2468')));

      await repository.removePin();
      FlutterSecureStorage.setMockInitialValues({});
      expect(await repository.hasPin(), isFalse);
    } finally {
      await settingsBox.deleteFromDisk();
      await directory.delete(recursive: true);
    }
  });

  test('legacy plaintext PIN is migrated without changing the PIN', () async {
    FlutterSecureStorage.setMockInitialValues({'app_pin': '8642'});
    const repository = SecurityRepository();

    expect(await repository.hasPin(), isTrue);
    expect(await repository.verifyPin('8642'), isTrue);
    expect(await repository.verifyPin('2468'), isFalse);

    final migrated = await const FlutterSecureStorage().read(key: 'app_pin');
    expect(migrated, isNotNull);
    expect(migrated, isNot('8642'));
    expect(migrated, isNot(contains('8642')));
  });

  test('recovery attempts cool down and stop at ten per day', () {
    var now = DateTime(2026, 7, 20, 10);
    var state = RecoveryAttemptState.fresh(now);

    for (var attempt = 1; attempt <= 10; attempt++) {
      state = state.afterFailure(now);
      if (attempt % RecoveryAttemptState.attemptsPerCooldown == 0 &&
          attempt < RecoveryAttemptState.maximumAttemptsPerDay) {
        now = now.add(RecoveryAttemptState.cooldownDuration);
        state = state.normalized(now);
      }
    }

    expect(state.failedToday, 10);
    expect(state.isDailyLocked, isTrue);
    expect(state.attemptsRemainingToday, 0);
    expect(state.normalized(DateTime(2026, 7, 21)).failedToday, 0);
  });
}
