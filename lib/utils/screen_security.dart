import 'package:flutter/services.dart';

/// Manages native window screen security (FLAG_SECURE) via MethodChannel.
abstract final class ScreenSecurity {
  static const MethodChannel _channel = MethodChannel('com.example.to_do/security');

  /// Configures screen security.
  /// If [allowScreenshots] is true, screenshots & screen recordings are allowed.
  /// If [allowScreenshots] is false, FLAG_SECURE is enforced to block capture.
  static Future<void> apply(bool allowScreenshots) async {
    try {
      await _channel.invokeMethod('setScreenSecurity', {
        'allowScreenshots': allowScreenshots,
      });
    } catch (_) {}
  }
}
