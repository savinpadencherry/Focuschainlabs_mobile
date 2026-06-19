import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/user.dart';
import '../../../core/repository/auth_repository.dart';
import '../../../core/services/auth/google_auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives sign-in, session restore and sign-out (spec F10). Holds the current
/// [AppUser] so the rest of the app can render role/org-aware surfaces.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final AppUser? user = await _authRepository.restoreSession();
    emit(user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user));
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final AppUser user = await _authRepository.signIn();
      emit(AuthState.authenticated(user));
    } on SignInCancelled {
      // User dismissed the picker — quietly return to login, no error.
      emit(const AuthState.unauthenticated());
    } catch (error) {
      emit(AuthState.unauthenticated(error: _readable(error)));
    }
  }

  String _readable(Object error) {
    final String raw = error.toString().replaceFirst('Exception: ', '');
    return raw.length > 200 ? '${raw.substring(0, 197)}…' : raw;
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const AuthState.unauthenticated());
  }
}
