import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/core/prototype/prototype_session.dart';
import 'package:amethyst/core/prototype/ui_only.dart';
import 'package:amethyst/core/network/api_exception.dart';

/// UI-only user admin: lists sample users; writes return [kUiOnlyMessage].
import 'package:amethyst/core/users/super_admin_users_port.dart';

final class PrototypeSuperAdminUsersService implements SuperAdminUsersPort {
  @override
  Future<List<Map<String, dynamic>>> listUsers({String? roleFilter}) async {
    _requireSuperAdmin();
    List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(PrototypeSampleData.users);
    if (roleFilter != null && roleFilter.isNotEmpty) {
      items = items
          .where((Map<String, dynamic> u) => u['role'] == roleFilter)
          .toList(growable: false);
    }
    return items;
  }

  @override
  Future<String?> createUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async =>
      kUiOnlyMessage;

  @override
  Future<String?> setUserActive({
    required String uid,
    required bool isActive,
  }) async =>
      kUiOnlyMessage;

  @override
  Future<String?> updateUser({
    required String uid,
    required String fullName,
    String? phone,
    required String role,
  }) async =>
      kUiOnlyMessage;

  @override
  Future<String?> sendPasswordReset({required String email}) async =>
      kUiOnlyMessage;

  void _requireSuperAdmin() {
    final user = PrototypeSession.current;
    if (user == null || user.role != 'super_admin') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
  }
}
