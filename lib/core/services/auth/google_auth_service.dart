import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/enums.dart';
import '../../models/user.dart';

/// Google Sign-In + Firebase Authentication, plus the Calendar read-only scope
/// so the same session can pull the user's meetings. Org/role are defaulted for
/// now and will be resolved from Data Connect once the schema is deployed.
class GoogleAuthService {
  GoogleAuthService()
      : _googleSignIn = GoogleSignIn(
          scopes: <String>['email', calendarReadonlyScope],
        );

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
      throw const _SignInCancelled();
    }
    final GoogleSignInAuthentication auth = await google.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    final UserCredential result = await _auth.signInWithCredential(credential);
    return _toAppUser(result.user!);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Whether the Calendar scope has been granted to the current session.
  bool get hasCalendarScope {
    final GoogleSignInAccount? a = _googleSignIn.currentUser;
    return a != null;
  }

  /// Request the Calendar scope if it wasn't granted at sign-in.
  Future<bool> connectCalendar() =>
      _googleSignIn.requestScopes(<String>[calendarReadonlyScope]);

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

class _SignInCancelled implements Exception {
  const _SignInCancelled();
  @override
  String toString() => 'Sign-in was cancelled.';
}
