import '../../get.dart';
import '../../models/listing.dart';
import '../../repository/crm_repository.dart';

/// The signed-in user, their organisation and their permissions — resolved
/// from the CRM once per app run.
///
/// All three used to have two sources. `/api/me` was one of them; the other
/// was `google_auth_service`, which built a user at sign-in with the
/// organisation hard-coded to `org-fcl` and the role to admin. That is right
/// for one tenant and one person and wrong for everybody else, and nothing on
/// screen distinguished the guess from the answer. There is one source now,
/// and it is the server.
///
/// Resolution is deduplicated rather than merely cached. Three surfaces ask
/// for this within the same frame at launch — the shell, the header avatar and
/// Profile — and a plain `if (current == null) fetch()` fired three identical
/// requests, because none of them had returned yet when the next one checked.
abstract final class IdentityCache {
  static Me? current;

  /// Why the last attempt failed, in the server's own words ("… is not a
  /// member of any organization"). Profile reports it; the header does not.
  static String lastError = '';

  static Future<Me>? _inFlight;

  /// What the caller may do. Never null: before the first answer this is
  /// [Access.unknown], which reproduces the app's previous behaviour rather
  /// than hiding controls the user probably has. The API is the real gate.
  static Access get access => current?.access ?? Access.unknown;

  /// The resolved user, fetching it if this is the first ask.
  ///
  /// Returns null rather than throwing: every caller is drawing a screen that
  /// has a reasonable shape without an identity, and [lastError] carries the
  /// detail for the one screen that reports it.
  static Future<Me?> ensure() async => current ?? await _resolve();

  /// Ask again — after a retry, or when a role change is expected.
  ///
  /// The known answer is kept until a new one arrives. Clearing it first made
  /// the header avatar behind the Profile page drop to a placeholder for the
  /// length of the round trip, which reads as a sign-out.
  static Future<Me?> refresh() {
    _inFlight = null;
    return _resolve();
  }

  static Future<Me?> _resolve() async {
    final Future<Me> pending = _inFlight ??= app<CrmRepository>().me();
    try {
      final Me me = await pending;
      current = me;
      lastError = '';
      return me;
    } catch (error) {
      lastError = _readable(error);
      return null;
    } finally {
      // Cleared either way: a failed call must not pin the failure for the
      // rest of the run, and a retry has to be able to make a fresh request.
      if (identical(_inFlight, pending)) _inFlight = null;
    }
  }

  static void clear() {
    current = null;
    _inFlight = null;
    lastError = '';
  }

  static String _readable(Object error) {
    final String raw = error.toString();
    final int colon = raw.indexOf('): ');
    return colon >= 0 ? raw.substring(colon + 3) : raw;
  }
}
