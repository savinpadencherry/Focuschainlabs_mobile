import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/enums.dart';
import '../../models/user.dart';

/// Google Sign-In + Firebase Authentication. Login requests only the basic
/// email/profile scopes so it never trips Google's unverified-app warning; the
/// sensitive Calendar scope is requested separately via [connectCalendar] (e.g.
/// from Profile). Org/role are defaulted until resolved from the backend.
class GoogleAuthService {
  GoogleAuthService()
      : _googleSignIn = GoogleSignIn(scopes: <String>['email']);

  static const String calendarReadonlyScope =
      'https://www.googleapis.com/auth/calendar.events.readonly';

  final GoogleSignIn _googleSignIn;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// The cached signed-in user, if any (session restore).
  AppUser? currentUser() {
    final User? user = _auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  /// Interactive Google sign-in → Firebase credential → [AppUser].
  Future<AppUser> signIn() async {
    final GoogleSignInAccount? google = await _googleSignIn.signIn();
    if (google == null) {
      throw const SignInCancelled();
    }
    final GoogleSignInAuthentication auth = await google.authentication;
    if (auth.idToken == null && auth.accessToken == null) {
      throw Exception(
        'Google did not return a token. Check that this app\'s SHA-1 is added '
        'in Firebase and Google sign-in is enabled.',
      );
    }
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    final UserCredential result = await _auth.signInWithCredential(credential);
    final User? user = result.user;
    if (user == null) throw Exception('Firebase returned no user.');
    return _toAppUser(user);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  bool _calendarConnected = false;

  /// Whether the Calendar scope has been granted this session.
  bool get hasCalendarScope => _calendarConnected;

  /// Request the sensitive Calendar scope on demand (separate from login).
  Future<bool> connectCalendar() async {
    try {
      if (_googleSignIn.currentUser == null) {
        await _googleSignIn.signInSilently();
      }
      _calendarConnected =
          await _googleSignIn.requestScopes(<String>[calendarReadonlyScope]);
      return _calendarConnected;
    } catch (_) {
      return false;
    }
  }

  /// Authenticated headers for direct Google Calendar REST calls. Refreshes the
  /// token silently when needed.
  Future<Map<String, String>?> calendarAuthHeaders() async {
    final GoogleSignInAccount? account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    return account.authHeaders;
  }

  AppUser _toAppUser(User user) => AppUser(
        id: user.uid,
        name: user.displayName ?? user.email?.split('@').first ?? 'Sales rep',
        email: user.email ?? '',
        // TODO: resolve from OrganizationMembership (Data Connect) once deployed.
        orgId: 'org-fcl',
        orgName: 'FocusChain Labs',
        role: UserRole.admin,
      );
}

/// Thrown when the user dismisses the Google account picker — not a real error.
class SignInCancelled implements Exception {
  const SignInCancelled();
  @override
  String toString() => 'Sign-in was cancelled.';
}
