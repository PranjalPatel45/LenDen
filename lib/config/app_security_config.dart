/// Developer Build Security Configuration.
abstract final class AppSecurityConfig {
  /// Set to `true` to ALLOW screenshots & screen recordings in the build.
  /// Set to `false` to BLOCK screenshots & screen recordings (enforce FLAG_SECURE).
  static const bool allowScreenshots = true;
}
