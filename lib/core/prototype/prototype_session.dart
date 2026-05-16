import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// In-memory session for UI prototype role preview (no Firebase Auth).
final class PrototypeSession {
  PrototypeSession._();

  static UserEntity? _current;

  static UserEntity? get current => _current;

  static bool get isSignedIn => _current != null;

  static UserEntity signInAsRole(String role) {
    final UserEntity user = switch (role) {
      'super_admin' => _superAdmin,
      'admin' => _admin,
      'driver' => _driver,
      _ => _admin,
    };
    _current = user;
    return user;
  }

  static void signOut() {
    _current = null;
  }

  static const UserEntity _superAdmin = UserEntity(
    id: 'proto_super',
    email: 'super@preview.local',
    fullName: 'مدير عام (عرض)',
    role: 'super_admin',
    phone: '+201000000001',
    isActive: true,
  );

  static const UserEntity _admin = UserEntity(
    id: 'proto_admin',
    email: 'admin@preview.local',
    fullName: 'مسؤول (عرض)',
    role: 'admin',
    phone: '+201000000002',
    isActive: true,
  );

  static const UserEntity _driver = UserEntity(
    id: 'proto_driver',
    email: 'driver@preview.local',
    fullName: 'سائق (عرض)',
    role: 'driver',
    phone: '+201000000003',
    isActive: true,
  );
}
