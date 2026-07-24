import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/data/security_repository.dart';

void main() {
  group('PIN attempt limits', () {
    test('starts a 30-second cooldown after three wrong attempts', () {
      final now = DateTime(2026, 7, 20, 10);
      var state = PinAttemptState.fresh(now);

      state = state.afterFailure(now);
      state = state.afterFailure(now);
      expect(state.isLockedAt(now), isFalse);

      state = state.afterFailure(now);
      expect(state.failedToday, 3);
      expect(state.isLockedAt(now), isTrue);
      expect(state.lockedUntil(now), now.add(const Duration(seconds: 30)));
      expect(
        state
            .normalized(now.add(const Duration(seconds: 30)))
            .isLockedAt(now.add(const Duration(seconds: 30))),
        isFalse,
      );
    });

    test('a successful PIN keeps the daily failure total', () {
      final now = DateTime(2026, 7, 20, 10);
      final state = PinAttemptState.fresh(
        now,
      ).afterFailure(now).afterFailure(now).afterSuccess(now);

      expect(state.failedToday, 2);
      expect(state.failedInCurrentGroup, 0);
      expect(state.attemptsRemainingToday, 13);
    });

    test('locks after 15 failures and resets on the next day', () {
      var now = DateTime(2026, 7, 20, 10);
      var state = PinAttemptState.fresh(now);

      for (var attempt = 1; attempt <= 15; attempt++) {
        state = state.afterFailure(now);
        if (attempt % PinAttemptState.attemptsPerCooldown == 0 &&
            attempt < PinAttemptState.maximumAttemptsPerDay) {
          now = now.add(PinAttemptState.cooldownDuration);
          state = state.normalized(now);
        }
      }

      expect(state.failedToday, 15);
      expect(state.attemptsRemainingToday, 0);
      expect(state.isDailyLocked, isTrue);
      expect(state.isLockedAt(now), isTrue);
      expect(state.lockedUntil(now), DateTime(2026, 7, 21));

      final tomorrow = DateTime(2026, 7, 21);
      final reset = state.normalized(tomorrow);
      expect(reset.failedToday, 0);
      expect(reset.isLockedAt(tomorrow), isFalse);
    });
  });
}
