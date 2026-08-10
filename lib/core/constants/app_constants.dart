/// App-wide constant values.
abstract final class AppConstants {
  static const String appName = 'Ona';
  static const String companyName = 'FocusChain Labs';
  static const String tagline = 'Your desk, in your pocket';
  static const String appVersion = '1.1.0';

  /// How long a surface waits before a background refresh is considered stale
  /// enough to redo on resume. The pipeline moves in minutes, not seconds.
  static const Duration refreshAfter = Duration(minutes: 2);
}

/// Persistence keys for [shared_preferences].
abstract final class StorageKeys {
  static const String session = 'secona.session.v1';
}
