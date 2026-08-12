import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

/// Product analytics event names.
///
/// **Never attach a name, a phone number, an email, a note, a chat message or
/// a lead id to an event.** This is a CRM: what a rep asked Ona about a client
/// is the client's business, and Google Analytics is not where it goes. The
/// parameters below are counts, durations and enum-like labels — enough to
/// answer "is the lead chat being used, and by how many people", never enough
/// to reconstruct who said what about whom.
abstract final class AnalyticsEvents {
  // Session
  static const String signInSuccess = 'sign_in_success';
  static const String signInFailed = 'sign_in_failed';
  static const String signOut = 'sign_out';
  static const String accessDenied = 'access_denied';

  // Ona
  static const String onaAsked = 'ona_asked';
  static const String onaChipTapped = 'ona_chip_tapped';
  static const String onaConfirmed = 'ona_confirmed';
  static const String onaDeclined = 'ona_declined';

  // Pipeline
  static const String leadOpened = 'lead_opened';
  static const String leadStageChanged = 'lead_stage_changed';
  static const String leadEdited = 'lead_edited';
  static const String leadNoteLogged = 'lead_note_logged';
  static const String leadSearched = 'lead_searched';

  // Lead chat
  static const String leadChatOpened = 'lead_chat_opened';
  static const String leadChatAsked = 'lead_chat_asked';

  // Listings
  static const String listingsSearched = 'listings_searched';
  static const String listingOpened = 'listing_opened';
  static const String listingShared = 'listing_shared';
  static const String listingEdited = 'listing_edited';
  static const String listingViewToggled = 'listing_view_toggled';
  static const String listingQuestionAsked = 'listing_question_asked';

  // Voice
  static const String dictationStarted = 'dictation_started';
  static const String dictationUnavailable = 'dictation_unavailable';

  // Reliability — what to look at when someone says "it broke"
  static const String apiFailed = 'api_failed';
}

/// Thin analytics contract so feature code stays decoupled from Firebase.
abstract interface class AnalyticsService {
  Future<void> log(String name, [Map<String, Object>? params]);
  Future<void> setUser(String? userId);

  /// Org and role, so usage can be read per workspace and per kind of user
  /// without identifying a person.
  Future<void> setWorkspace({required String orgId, required String role});

  Future<void> screen(String name);

  /// Attach to MaterialApp so pushed routes are counted without every screen
  /// remembering to log itself.
  NavigatorObserver? get observer;
}

/// Firebase-backed analytics (active once Firebase is initialised).
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  NavigatorObserver? get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Analytics must never be the reason an action fails, so every call here
  /// swallows its own errors. A dropped event is a gap in a chart; an
  /// exception here would be a rep unable to log a note.
  Future<void> _safely(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {}
  }

  @override
  Future<void> log(String name, [Map<String, Object>? params]) =>
      _safely(() => _analytics.logEvent(name: name, parameters: params));

  @override
  Future<void> setUser(String? userId) =>
      _safely(() => _analytics.setUserId(id: userId));

  @override
  Future<void> setWorkspace({required String orgId, required String role}) =>
      _safely(() async {
        await _analytics.setUserProperty(name: 'org_id', value: orgId);
        await _analytics.setUserProperty(name: 'role', value: role);
      });

  @override
  Future<void> screen(String name) =>
      _safely(() => _analytics.logScreenView(screenName: name));
}

/// No-op analytics, used when Firebase is absent (tests, a build without
/// google-services.json).
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  NavigatorObserver? get observer => null;

  @override
  Future<void> log(String name, [Map<String, Object>? params]) async {}

  @override
  Future<void> setUser(String? userId) async {}

  @override
  Future<void> setWorkspace({
    required String orgId,
    required String role,
  }) async {}

  @override
  Future<void> screen(String name) async {}
}
