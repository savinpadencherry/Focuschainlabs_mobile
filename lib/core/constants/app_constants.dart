/// App-wide constant values and feature flags.
abstract final class AppConstants {
  static const String appName = 'Mr. Rex';
  static const String companyName = 'FocusChain Labs';
  static const String tagline = 'Your sales companion';
  static const String appVersion = '0.3.0';

  /// When true, repositories serve seeded in-memory/persisted data instead of
  /// calling Supabase / Claude. Flip to false once real backends are wired
  /// (see docs/SETUP.md). Demo mode lets the full MVP loop run with no keys.
  static const bool demoMode = true;

  /// Short window during which an external write (CRM/task/calendar) can be
  /// undone with one tap — see F5/F6 reversibility requirement.
  static const Duration undoWindow = Duration(seconds: 6);

  /// Simulated latency so mock async calls feel like real network round-trips.
  static const Duration mockLatency = Duration(milliseconds: 650);
}

/// Persistence keys for [shared_preferences].
abstract final class StorageKeys {
  static const String session = 'mrrex.session.v1';
  static const String captures = 'mrrex.captures.v1';
  static const String activity = 'mrrex.activity.v1';
}
