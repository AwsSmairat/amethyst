import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';

abstract interface class UserDashboardRepository {
  Future<DriverDashboard> getDriverDashboard({required String driverDisplayName});
}

