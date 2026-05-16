import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/users/super_admin_users_port.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class SuperAdminUsersCubit extends Cubit<ListLoadState> {
  SuperAdminUsersCubit(this._service, {this.roleFilter})
      : super(const ListLoadInitial());

  final SuperAdminUsersPort _service;
  final String? roleFilter;

  Future<void> load() async {
    emit(const ListLoadLoading());
    try {
      final List<Map<String, dynamic>> items =
          await _service.listUsers(roleFilter: roleFilter);
      emit(ListLoadLoaded(items));
    } on Object catch (e) {
      emit(ListLoadFailure(e.toString()));
    }
  }

  Future<String?> createUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    final String? err = await _service.createUser(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
    if (err == null) {
      await load();
    }
    return err;
  }

  Future<String?> setUserActive({
    required String uid,
    required bool isActive,
  }) async {
    final String? err = await _service.setUserActive(uid: uid, isActive: isActive);
    if (err == null) {
      await load();
    }
    return err;
  }

  Future<String?> updateUser({
    required String uid,
    required String fullName,
    String? phone,
    required String role,
  }) async {
    final String? err = await _service.updateUser(
      uid: uid,
      fullName: fullName,
      phone: phone,
      role: role,
    );
    if (err == null) {
      await load();
    }
    return err;
  }

  Future<String?> sendPasswordReset({required String email}) async {
    return _service.sendPasswordReset(email: email);
  }
}
