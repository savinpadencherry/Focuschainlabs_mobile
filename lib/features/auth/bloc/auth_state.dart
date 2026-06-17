part of 'auth_bloc.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._(this.status, [this.user]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.authenticated(AppUser user)
      : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  @override
  List<Object?> get props => <Object?>[status, user];
}
