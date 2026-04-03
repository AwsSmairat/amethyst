import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminVehiclesCubit extends Cubit<ListLoadState> {
  SuperAdminVehiclesCubit(this._api) : super(const ListLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    emit(const ListLoadLoading());
    try {
      final Map<String, dynamic> data = await _api.listVehicles(limit: 100);
      final raw = data['items'];
      final items = <Map<String, dynamic>>[];
      if (raw is List<dynamic>) {
        for (final dynamic e in raw) {
          if (e is Map<String, dynamic>) {
            items.add(e);
          }
        }
      }
      emit(ListLoadLoaded(items));
    } on Object catch (e) {
      emit(ListLoadFailure(e.toString()));
    }
  }

  Future<String?> createVehicle({
    required String vehicleNumber,
    String? driverId,
    String? notes,
  }) async {
    try {
      await _api.createVehicle(
        vehicleNumber: vehicleNumber,
        driverId: driverId,
        notes: notes,
      );
      await load();
      return null;
    } on Object catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteVehicle(String id) async {
    try {
      await _api.deleteVehicle(id);
      await load();
      return null;
    } on Object catch (e) {
      return e.toString();
    }
  }
}
