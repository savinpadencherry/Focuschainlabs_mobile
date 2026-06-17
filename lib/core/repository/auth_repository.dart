import '../constants/app_constants.dart';
import '../data/seed_data.dart';
import '../models/user.dart';
import '../services/local_store.dart';

/// Owns authentication and the current [AppUser]. In demo mode it signs the
/// user in as FCL's admin and persists the session; the public surface matches
/// what a Supabase Auth implementation would expose (spec F10).
class AuthRepository {
  AuthRepository({required LocalStore store}) : _store = store;

  final LocalStore _store;

  /// Returns the cached user if a session exists, else null.
  Future<AppUser?> restoreSession() async {
    if (!AppConstants.demoMode) return null;
    final Map<String, dynamic>? json = await _store.readJson(StorageKeys.session);
    return json == null ? null : AppUser.fromJson(json);
  }

  /// Google / email sign-in. Demo mode resolves to the seeded FCL admin.
  Future<AppUser> signIn() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    const AppUser user = SeedData.user;
    await _store.writeJson(StorageKeys.session, user.toJson());
    return user;
  }

  Future<void> signOut() async {
    await _store.remove(StorageKeys.session);
  }
}
