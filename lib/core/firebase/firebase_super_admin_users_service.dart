import 'package:amethyst/core/firebase/firebase_auth_service.dart';
import 'package:amethyst/core/firebase/firestore_mappers.dart';
import 'package:amethyst/core/firebase/firestore_paths.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/core/users/super_admin_users_port.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// إدارة المستخدمين عبر Cloud Functions + قراءة Firestore.
final class FirebaseSuperAdminUsersService implements SuperAdminUsersPort {
  FirebaseSuperAdminUsersService({
    required FirebaseAuthService authService,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = authService,
        _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuthService _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Future<List<Map<String, dynamic>>> listUsers({String? roleFilter}) async {
    await _requireSuperAdmin();
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestorePaths.users).orderBy('fullName').get();
    List<Map<String, dynamic>> items = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => mapUserDoc(d))
        .toList(growable: false);
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
  }) async {
    try {
      await _call('createUserBySuperAdmin', <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': role,
      });
      return null;
    } on Object catch (e) {
      return _messageFrom(e);
    }
  }

  @override
  Future<String?> setUserActive({
    required String uid,
    required bool isActive,
  }) async {
    try {
      await _call('setUserActiveStatus', <String, dynamic>{
        'uid': uid,
        'isActive': isActive,
      });
      return null;
    } on Object catch (e) {
      return _messageFrom(e);
    }
  }

  @override
  Future<String?> updateUser({
    required String uid,
    required String fullName,
    String? phone,
    required String role,
  }) async {
    try {
      await _call('updateUserBySuperAdmin', <String, dynamic>{
        'uid': uid,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': role,
      });
      return null;
    } on Object catch (e) {
      return _messageFrom(e);
    }
  }

  @override
  Future<String?> sendPasswordReset({required String email}) async {
    try {
      await _call('sendPasswordResetBySuperAdmin', <String, dynamic>{
        'email': email,
      });
      return null;
    } on Object catch (e) {
      return _messageFrom(e);
    }
  }

  Future<void> _requireSuperAdmin() async {
    final user = await _auth.loadCurrentUser();
    if (user.role != 'super_admin') {
      throw ApiException('Forbidden', code: 'FORBIDDEN');
    }
  }

  Future<void> _call(String name, Map<String, dynamic> data) async {
    final HttpsCallable callable = _functions.httpsCallable(name);
    await callable.call(data);
  }

  String _messageFrom(Object error) {
    if (error is FirebaseFunctionsException) {
      return error.message ?? error.code;
    }
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
