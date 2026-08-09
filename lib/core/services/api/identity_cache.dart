import '../../models/listing.dart';

/// The signed-in user, resolved once per app run.
///
/// Three surfaces each render a header with the user's initials in it; without
/// this they would each call `/api/me` on every rebuild to draw a 38px circle,
/// and the answer changes about as often as someone changes job.
///
/// It lives here rather than as a static on the avatar widget so that Profile
/// can clear it on sign-out without the two files importing each other.
abstract final class IdentityCache {
  static Me? current;

  static void clear() => current = null;
}
