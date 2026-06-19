import '../models/user.dart';
import '../services/auth/google_auth_service.dart';
import '../services/firebase/analytics_service.dart';
import 'auth_repository.dart';

/// Production auth backed by Firebase + Google Sign-In.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required GoogleAuthService google,
    required AnalyticsService analytics,
  })  : _google = google,
        _analytics = analytics;

  final GoogleAuthService _google;
  final AnalyticsService _analytics;

  @override
  Future<AppUser?> restoreSession() async => _google.currentUser();

  @override
  Future<AppUser> signIn() async {
    final AppUser user = await _google.signIn();
    // Analytics must never break a successful sign-in.
    _track(() async {
      await _analytics.setUser(user.id);
      await _analytics.log(AnalyticsEvents.signInSuccess);
    });
    return user;
  }

  @override
  Future<void> signOut() async {
    _track(() => _analytics.log(AnalyticsEvents.signOut));
    _track(() => _analytics.setUser(null));
    await _google.signOut();
  }

  void _track(Future<void> Function() op) {
    op().catchError((_) {});
  }
}
