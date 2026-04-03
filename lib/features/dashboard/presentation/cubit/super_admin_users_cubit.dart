import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminUsersCubit extends Cubit<ListLoadState> {
  SuperAdminUsersCubit(this._api) : super(const ListLoadInitial());

  final AmethystApi _api;

  Future<void> load() async {
    emit(const ListLoadLoading());
    try {
      // Server validates `limit` with max 100 (see listQuerySchema).
      final Map<String, dynamic> data = await _api.listUsers(limit: 100);
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

  Future<String?> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _api.createUser(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      await load();
      return null;
    } on Object catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteUser(String id) async {
    try {
      await _api.deleteUser(id);
      await load();
      return null;
    } on Object catch (e) {
      return e.toString();
    }
  }
}
