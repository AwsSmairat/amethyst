import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:amethyst/features/auth/domain/usecases/load_session_usecase.dart';
import 'package:amethyst/features/auth/domain/usecases/login_usecase.dart';
import 'package:amethyst/features/auth/domain/usecases/logout_usecase.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required LoginUseCase loginUseCase,
    required LoadSessionUseCase loadSessionUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _loadSessionUseCase = loadSessionUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final LoadSessionUseCase _loadSessionUseCase;
  final LogoutUseCase _logoutUseCase;

  Future<void> checkSession() async {
    emit(const AuthLoading());
    try {
      final UserEntity user = await _loadSessionUseCase();
      emit(AuthAuthenticated(user));
    } on Object {
      emit(const AuthUnauthenticated());
    }
  }

  /// UI preview: sign in as a role (persists session like normal login).
  Future<void> previewAsRole(String role) async {
    emit(const AuthLoading());
    try {
      final UserEntity user = await PrototypeSession.signInAsRole(role);
      emit(AuthAuthenticated(user));
    } on Object catch (e) {
      emit(AuthUnauthenticated(message: e.toString()));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await _loginUseCase(email: email, password: password);
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      final String msg = uiOnlyErrorMessage(e) ??
          ((e.code != null && e.code!.isNotEmpty)
              ? '${e.message} (${e.code})'
              : e.message);
      emit(AuthUnauthenticated(message: msg));
    } on Object catch (e) {
      emit(AuthUnauthenticated(message: e.toString()));
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    emit(const AuthUnauthenticated());
  }

  void handleUnauthorized() {
    emit(const AuthUnauthenticated());
  }
}
