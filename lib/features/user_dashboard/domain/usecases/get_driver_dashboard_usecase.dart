import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';
import 'package:amethyst/features/user_dashboard/domain/repositories/user_dashboard_repository.dart';

class GetDriverDashboardUseCase {
  const GetDriverDashboardUseCase({required UserDashboardRepository repository})
      : _repository = repository;

  final UserDashboardRepository _repository;

  Future<DriverDashboard> call() => _repository.getDriverDashboard();
}

