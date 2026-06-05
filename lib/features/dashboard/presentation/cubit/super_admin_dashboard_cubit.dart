import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminDashboardCubit extends Cubit<DashboardLoadState> {
  SuperAdminDashboardCubit(this._api) : super(const DashboardLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    if (isClosed) {
      return;
    }
    emit(const DashboardLoadLoading());
    try {
      final data = await _api
          .getDashboardSuperAdmin()
          .timeout(const Duration(seconds: 45));
      if (!isClosed) {
        emit(DashboardLoadSuccess(data));
      }
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(DashboardLoadFailure(e.message));
      }
    } on Object catch (e) {
      if (!isClosed) {
        emit(DashboardLoadFailure(e.toString()));
      }
    }
  }
}
