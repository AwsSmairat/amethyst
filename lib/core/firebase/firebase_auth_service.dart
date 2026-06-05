import 'package:amethyst/core/firebase/firestore_mappers.dart';
import 'package:amethyst/core/firebase/firestore_paths.dart';
import 'package:amethyst/core/network/api_exception.dart';
import 'package:amethyst/features/auth/domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
final class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final User? user = cred.user;
      if (user == null) {
        throw ApiException('Invalid credentials', code: 'INVALID_CREDENTIALS');
      }
      return _loadUserProfile(user.uid);
    } on FirebaseAuthException catch (e) {
      throw ApiException(
        _authMessage(e),
        code: e.code.toUpperCase(),
      );
    }
  }

  Future<UserEntity> loadCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw ApiException('Not authenticated', code: 'UNAUTHORIZED');
    }
    return _loadUserProfile(user.uid);
  }

  Future<void> logout() => _auth.signOut();

  Future<UserEntity> _loadUserProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ApiException(
          'لا صلاحية لقراءة ملف المستخدم — تحقق من مستند users في Firestore',
          code: 'PERMISSION_DENIED',
        );
      }
      rethrow;
    }
    if (!doc.exists) {
      throw ApiException(
        'ملف المستخدم غير موجود في Firestore — أنشئ مستند users/{uid}',
        code: 'NOT_FOUND',
      );
    }
    final Map<String, dynamic> data = mapUserDoc(doc);
    if (data['isActive'] == false) {
      await _auth.signOut();
      throw ApiException('Account is inactive', code: 'FORBIDDEN');
    }
    return UserEntity.fromJson(data);
  }

  Future<Map<String, dynamic>> currentActor() async {
    final UserEntity user = await loadCurrentUser();
    return <String, dynamic>{
      'id': user.id,
      'role': user.role,
      'fullName': user.fullName,
      'email': user.email,
    };
  }

  Future<UserEntity> createUserAccount({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'AmethystSecondary',
      options: Firebase.app().options,
    );
    try {
      final FirebaseAuth secondaryAuth =
          FirebaseAuth.instanceFor(app: secondaryApp);
      final UserCredential cred =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final String uid = cred.user!.uid;
      await _firestore.collection(FirestorePaths.users).doc(uid).set(<String, dynamic>{
        'fullName': fullName,
        'email': email.trim().toLowerCase(),
        'phone': phone,
        'role': role,
        'isActive': true,
        'createdAt': serverTimestamp(),
        'updatedAt': serverTimestamp(),
      });
      await secondaryAuth.signOut();
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(FirestorePaths.users).doc(uid).get();
      return UserEntity.fromJson(mapUserDoc(doc));
    } on FirebaseAuthException catch (e) {
      throw ApiException(_authMessage(e), code: e.code.toUpperCase());
    } finally {
      await secondaryApp.delete();
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'user-disabled':
        return 'Account is inactive';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
