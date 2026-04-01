import 'package:amethyst/core/storage/secure_token_storage.dart';
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
    required TokenStorage tokenStorage,
  })  : _loginUseCase = loginUseCase,
        _loadSessionUseCase = loadSessionUseCase,
        _logoutUseCase = logoutUseCase,
        _tokenStorage = tokenStorage,
        super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final LoadSessionUseCase _loadSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final TokenStorage _tokenStorage;

  Future<void> checkSession() async {
    emit(const AuthLoading());
    String? token;
    try {
      token = await _tokenStorage.readToken();
    } on Object {
      await _logoutUseCase();
      emit(const AuthUnauthenticated());
      return;
    }
    if (token == null || token.isEmpty) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final user = await _loadSessionUseCase();
      emit(AuthAuthenticated(user));
    } on Object {
      await _logoutUseCase();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await _loginUseCase(email: email, password: password);
      emit(AuthAuthenticated(user));
    } on Object catch (e) {
      emit(AuthUnauthenticated(message: e.toString()));
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    emit(const AuthUnauthenticated());
  }

  /// Called when the API returns 401 (token cleared by [DioClient]).
  void handleUnauthorized() {
    emit(const AuthUnauthenticated());
  }
}
