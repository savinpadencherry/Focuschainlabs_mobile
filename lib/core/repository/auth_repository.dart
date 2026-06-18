import '../constants/app_constants.dart';
import '../data/seed_data.dart';
import '../models/user.dart';
import '../services/local_store.dart';

/// Authentication contract (spec F10). Implemented by [DemoAuthRepository]
/// (seeded session) and [FirebaseAuthRepository] (Google sign-in); the bloc
/// depends only on this interface.
abstract interface class AuthRepository {
  /// Returns the cached/current user if a session exists, else null.
  Future<AppUser?> restoreSession();

  /// Interactive sign-in.
  Future<AppUser> signIn();

  Future<void> signOut();
}

/// Offline auth: signs in as FCL's admin and persists the session locally.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({required LocalStore store}) : _store = store;

  final LocalStore _store;

  @override
  Future<AppUser?> restoreSession() async {
    final Map<String, dynamic>? json = await _store.readJson(StorageKeys.session);
    return json == null ? null : AppUser.fromJson(json);
  }

  @override
  Future<AppUser> signIn() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    const AppUser user = SeedData.user;
    await _store.writeJson(StorageKeys.session, user.toJson());
    return user;
  }

  @override
  Future<void> signOut() async => _store.remove(StorageKeys.session);
}
