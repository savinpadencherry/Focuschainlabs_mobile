part of 'auth_bloc.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, {this.user, this.error});

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.unauthenticated({String? error})
      : this._(AuthStatus.unauthenticated, error: error);
  const AuthState.authenticated(AppUser user)
      : this._(AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AppUser? user;

  /// Set when a sign-in attempt failed (shown on the login screen).
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  @override
  List<Object?> get props => <Object?>[status, user, error];
}
