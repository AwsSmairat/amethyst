import 'package:amethyst/core/firebase/amethyst_firebase_backend.dart';
import 'package:amethyst/core/firebase/firebase_auth_service.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_dashboard_cubit.dart';
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
    required FirebaseAuthService authService,
  })  : _loginUseCase = loginUseCase,
        _loadSessionUseCase = loadSessionUseCase,
        _logoutUseCase = logoutUseCase,
        _authService = authService,
        super(const AuthInitial());

  final LoginUseCase _loginUseCase;
  final LoadSessionUseCase _loadSessionUseCase;
  final LogoutUseCase _logoutUseCase;
  final FirebaseAuthService _authService;

  Future<void> checkSession() async {
    emit(const AuthLoading());
    if (_authService.currentFirebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final user = await _loadSessionUseCase();
      emit(AuthAuthenticated(user));
    } on Object {
      await _logoutUseCase();
      sl<AmethystFirebaseBackend>().clearCatalogCache();
      sl<SuperAdminDashboardCubit>().reset();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final user = await _loginUseCase(email: email, password: password);
      emit(AuthAuthenticated(user));
    } on ApiException catch (e) {
      final String msg = (e.code != null && e.code!.isNotEmpty)
          ? '${e.message} (${e.code})'
          : e.message;
      emit(AuthUnauthenticated(message: msg));
    } on Object catch (e) {
      emit(AuthUnauthenticated(message: e.toString()));
    }
  }

  Future<void> logout() async {
    await _logoutUseCase();
    sl<AmethystFirebaseBackend>().clearCatalogCache();
    sl<SuperAdminDashboardCubit>().reset();
    emit(const AuthUnauthenticated());
  }

  void handleUnauthorized() {
    emit(const AuthUnauthenticated());
  }
}
