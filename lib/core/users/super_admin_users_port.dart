abstract class SuperAdminUsersPort {
  Future<List<Map<String, dynamic>>> listUsers({String? roleFilter});

  Future<String?> createUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
  });

  Future<String?> setUserActive({
    required String uid,
    required bool isActive,
  });

  Future<String?> updateUser({
    required String uid,
    required String fullName,
    String? phone,
    required String role,
  });

  Future<String?> sendPasswordReset({required String email});
}
