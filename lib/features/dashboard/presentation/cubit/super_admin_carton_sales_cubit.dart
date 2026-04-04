import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/dashboard_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminCartonSalesCubit extends Cubit<DashboardLoadState> {
  SuperAdminCartonSalesCubit(this._api) : super(const DashboardLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    emit(const DashboardLoadLoading());
    try {
      final Map<String, dynamic> data = await _api.getSuperAdminCartonSummary();
      emit(DashboardLoadSuccess(data));
    } on Object catch (e) {
      emit(DashboardLoadFailure(e.toString()));
    }
  }
}
