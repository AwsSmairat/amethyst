import 'package:amethyst/features/user_dashboard/data/datasources/user_dashboard_local_datasource.dart';
import 'package:amethyst/features/user_dashboard/data/repositories/user_dashboard_repository_impl.dart';
import 'package:amethyst/features/user_dashboard/domain/repositories/user_dashboard_repository.dart';
import 'package:amethyst/features/user_dashboard/domain/usecases/get_driver_dashboard_usecase.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_cubit.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  // User Dashboard - data
  sl.registerLazySingleton<UserDashboardLocalDataSource>(
    () => const UserDashboardLocalDataSource(),
  );
  sl.registerLazySingleton<UserDashboardRepository>(
    () => UserDashboardRepositoryImpl(localDataSource: sl()),
  );

  // User Dashboard - domain
  sl.registerLazySingleton<GetDriverDashboardUseCase>(
    () => GetDriverDashboardUseCase(repository: sl()),
  );

  // User Dashboard - presentation
  sl.registerFactory<UserDashboardCubit>(
    () => UserDashboardCubit(getDashboard: sl()),
  );
}

