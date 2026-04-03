import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/network/dio_client.dart';
import 'package:amethyst/core/storage/secure_token_storage.dart';
import 'package:amethyst/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:amethyst/features/auth/domain/repositories/auth_repository.dart';
import 'package:amethyst/features/auth/domain/usecases/load_session_usecase.dart';
import 'package:amethyst/features/auth/domain/usecases/login_usecase.dart';
import 'package:amethyst/features/auth/domain/usecases/logout_usecase.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/record_operations/data/repositories/record_operations_repository_impl.dart';
import 'package:amethyst/features/record_operations/domain/repositories/record_operations_repository.dart';
import 'package:amethyst/features/admin/domain/usecases/save_station_balance_usecase.dart';
import 'package:amethyst/features/record_operations/domain/usecases/record_operation_usecases.dart';
import 'package:amethyst/features/user_dashboard/data/repositories/user_dashboard_repository_impl.dart';
import 'package:amethyst/features/user_dashboard/domain/repositories/user_dashboard_repository.dart';
import 'package:amethyst/features/user_dashboard/domain/usecases/get_driver_dashboard_usecase.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_cubit.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<TokenStorage>(FallbackTokenStorage.new);

  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      tokenStorage: sl<TokenStorage>(),
      onUnauthorized: () {
        if (sl.isRegistered<AuthCubit>()) {
          sl<AuthCubit>().handleUnauthorized();
        }
      },
    ),
  );

  sl.registerLazySingleton<AmethystApi>(
    () => AmethystApi(sl<DioClient>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      api: sl<AmethystApi>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LoadSessionUseCase>(
    () => LoadSessionUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      loadSessionUseCase: sl<LoadSessionUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );

  sl.registerLazySingleton<RecordOperationsRepository>(
    () => RecordOperationsRepositoryImpl(sl<AmethystApi>()),
  );

  sl.registerLazySingleton<ListProductItemsUseCase>(
    () => ListProductItemsUseCase(sl<RecordOperationsRepository>()),
  );
  sl.registerLazySingleton<CreateStationSaleUseCase>(
    () => CreateStationSaleUseCase(sl<RecordOperationsRepository>()),
  );
  sl.registerLazySingleton<CreateVehicleSaleUseCase>(
    () => CreateVehicleSaleUseCase(sl<RecordOperationsRepository>()),
  );
  sl.registerLazySingleton<CreateExpenseUseCase>(
    () => CreateExpenseUseCase(sl<RecordOperationsRepository>()),
  );
  sl.registerLazySingleton<CreateReturnUseCase>(
    () => CreateReturnUseCase(sl<RecordOperationsRepository>()),
  );
  sl.registerLazySingleton<CreateVehicleLoadUseCase>(
    () => CreateVehicleLoadUseCase(sl<RecordOperationsRepository>()),
  );
  sl.registerLazySingleton<SaveStationBalanceUseCase>(
    () => SaveStationBalanceUseCase(sl<RecordOperationsRepository>()),
  );

  sl.registerLazySingleton<UserDashboardRepository>(
    () => UserDashboardRepositoryImpl(api: sl<AmethystApi>()),
  );

  sl.registerLazySingleton<GetDriverDashboardUseCase>(
    () => GetDriverDashboardUseCase(repository: sl<UserDashboardRepository>()),
  );

  sl.registerFactory<UserDashboardCubit>(
    () => UserDashboardCubit(getDashboard: sl<GetDriverDashboardUseCase>()),
  );
}
