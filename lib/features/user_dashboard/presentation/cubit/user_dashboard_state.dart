import 'package:amethyst/features/user_dashboard/domain/entities/driver_dashboard.dart';
import 'package:equatable/equatable.dart';

sealed class UserDashboardState extends Equatable {
  const UserDashboardState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class UserDashboardInitial extends UserDashboardState {
  const UserDashboardInitial();
}

final class UserDashboardLoading extends UserDashboardState {
  const UserDashboardLoading();
}

final class UserDashboardLoaded extends UserDashboardState {
  const UserDashboardLoaded(this.dashboard);

  final DriverDashboard dashboard;

  @override
  List<Object?> get props => <Object?>[dashboard];
}

final class UserDashboardError extends UserDashboardState {
  const UserDashboardError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

