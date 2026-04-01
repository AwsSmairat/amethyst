import 'package:amethyst/features/user_dashboard/domain/usecases/get_driver_dashboard_usecase.dart';
import 'package:amethyst/features/user_dashboard/presentation/cubit/user_dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserDashboardCubit extends Cubit<UserDashboardState> {
  UserDashboardCubit({required GetDriverDashboardUseCase getDashboard})
      : _getDashboard = getDashboard,
        super(const UserDashboardInitial());

  final GetDriverDashboardUseCase _getDashboard;

  Future<void> load({required String driverDisplayName}) async {
    emit(const UserDashboardLoading());
    try {
      final dashboard = await _getDashboard(driverDisplayName: driverDisplayName);
      emit(UserDashboardLoaded(dashboard));
    } catch (e) {
      emit(UserDashboardError(e.toString()));
    }
  }
}

