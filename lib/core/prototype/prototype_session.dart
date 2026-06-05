import 'package:amethyst/core/prototype/prototype_local_store.dart';
import 'package:amethyst/core/prototype/prototype_sample_data.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';

/// Prototype session with optional persistence across app restarts.
final class PrototypeSession {
  PrototypeSession._();

  static UserEntity? _current;

  static UserEntity? get current => _current;

  static bool get isSignedIn => _current != null;

  static Future<UserEntity> signInAsRole(String role) async {
    final UserEntity user = PrototypeSampleData.previewUserForRole(role);
    await signIn(user);
    return user;
  }

  static Future<void> signIn(UserEntity user) async {
    _current = user;
    await PrototypeLocalStore.persistSessionUserId(user.id);
  }

  static Future<bool> restoreFromStorage() async {
    final String? userId = await PrototypeLocalStore.readSessionUserId();
    if (userId == null || userId.isEmpty) {
      return false;
    }
    final UserEntity? user = PrototypeSampleData.userEntityById(userId);
    if (user == null || !user.isActive) {
      await PrototypeLocalStore.persistSessionUserId(null);
      return false;
    }
    _current = user;
    return true;
  }

  static Future<void> signOut() async {
    _current = null;
    await PrototypeLocalStore.persistSessionUserId(null);
  }
}
