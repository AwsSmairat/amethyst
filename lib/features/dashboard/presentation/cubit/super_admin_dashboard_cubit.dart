import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminDashboardCubit extends Cubit<DashboardLoadState> {
  SuperAdminDashboardCubit(this._api) : super(const DashboardLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    emit(const DashboardLoadLoading());
    try {
      final data = await _api.getDashboardSuperAdmin();
      emit(DashboardLoadSuccess(data));
    } on Object catch (e) {
      emit(DashboardLoadFailure(e.toString()));
    }
  }
}
