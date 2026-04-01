import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/user_dashboard/data/mappers/driver_dashboard_mapper.dart';
import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';
import 'package:amethyst/features/user_dashboard/domain/repositories/user_dashboard_repository.dart';

final class UserDashboardRepositoryImpl implements UserDashboardRepository {
  UserDashboardRepositoryImpl({required AmethystApi api}) : _api = api;

  final AmethystApi _api;

  @override
  Future<DriverDashboard> getDriverDashboard({required String driverDisplayName}) async {
    final json = await _api.getDashboardDriver();
    return mapDriverDashboardApi(json, driverDisplayName: driverDisplayName);
  }
}
