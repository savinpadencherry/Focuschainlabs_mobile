import '../models/user.dart';

/// Authentication contract. Implemented by [FirebaseAuthRepository].
///
/// There is no demo implementation. Signing in is what tells the CRM which
/// tenant and role the caller has, so a session that was not obtained from
/// Google cannot read anything anyway.
abstract interface class AuthRepository {
  /// The current user if a session survives, else null.
  Future<AppUser?> restoreSession();

  /// Interactive Google sign-in.
  Future<AppUser> signIn();

  Future<void> signOut();
}
