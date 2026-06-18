import 'package:firebase_analytics/firebase_analytics.dart';

/// Product analytics event names. Never attach transcripts, tokens, private
/// notes or personal contact details as parameters.
abstract final class AnalyticsEvents {
  static const String signInSuccess = 'sign_in_success';
  static const String signOut = 'sign_out';
  static const String calendarConnected = 'calendar_connected';
  static const String calendarSyncFailed = 'calendar_sync_failed';
  static const String captureStarted = 'capture_started';
  static const String captureConfirmed = 'capture_confirmed';
  static const String crmWriteSuccess = 'crm_write_success';
  static const String crmWriteFailed = 'crm_write_failed';
  static const String trelloWriteSuccess = 'trello_write_success';
  static const String undoUsed = 'undo_used';
}

/// Thin analytics contract so feature code stays decoupled from Firebase.
abstract interface class AnalyticsService {
  Future<void> log(String name, [Map<String, Object>? params]);
  Future<void> setUser(String? userId);
}

/// Firebase-backed analytics (active once Firebase is initialised).
class FirebaseAnalyticsService implements AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> log(String name, [Map<String, Object>? params]) =>
      _analytics.logEvent(name: name, parameters: params);

  @override
  Future<void> setUser(String? userId) => _analytics.setUserId(id: userId);
}

/// No-op analytics for demo mode / tests.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> log(String name, [Map<String, Object>? params]) async {}

  @override
  Future<void> setUser(String? userId) async {}
}
