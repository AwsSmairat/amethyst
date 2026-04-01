import 'package:amethyst/features/user_dashboard/data/datasources/user_dashboard_local_datasource.dart';
import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';
import 'package:amethyst/features/user_dashboard/domain/repositories/user_dashboard_repository.dart';

class UserDashboardRepositoryImpl implements UserDashboardRepository {
  const UserDashboardRepositoryImpl({
    required UserDashboardLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final UserDashboardLocalDataSource _localDataSource;

  @override
  Future<DriverDashboard> getDriverDashboard() async {
    final model = await _localDataSource.getDriverDashboard();
    return model.toEntity();
  }
}

