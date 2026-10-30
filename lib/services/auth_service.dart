import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'student_data_service.dart';
import 'account_api.dart';

class AuthService {
  AuthService({required this.auth, required this.data, AccountApi? api})
    : api = api ?? AccountApi(auth);
  final FirebaseAuth auth;
  final StudentDataService data;
  final AccountApi api;
  bool verificationSent = false;
  Stream<User?> get authStateChanges => auth.authStateChanges();
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      final profile = await data.users.getById(credential.user!.uid);
      if (profile == null) {
        throw StateError('Tài khoản chưa được liên kết hồ sơ. Liên hệ Admin.');
      }
      return profile;
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  Future<AppUser> registerLecturer({
    required String email,
    required String password,
    required String name,
    required String lecturerCode,
  }) async {
    await api.call('/register-lecturer', {
      'email': email.trim(),
      'password': password,
      'displayName': name.trim(),
      'lecturerCode': lecturerCode.trim(),
    }, authenticated: false);
    final profile = await signIn(email: email, password: password);
    try {
      await auth.currentUser!.sendEmailVerification();
      verificationSent = true;
    } catch (_) {
      verificationSent = false;
    }
    return profile;
  }

  Future<AppUser> refreshProfile() async {
    await auth.currentUser?.reload();
    await auth.currentUser?.getIdToken(true);
    final profile = await data.users.getById(auth.currentUser!.uid);
    if (profile == null) throw StateError('Hồ sơ không còn tồn tại.');
    return profile;
  }

  Future<void> sendVerification() async {
    await auth.currentUser!.sendEmailVerification();
    verificationSent = true;
  }

  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email);
  Future<void> updateDisplayName(AppUser user, String value) =>
      data.users.collection.doc(user.uid).update({
        'displayName': user.copyWith(displayName: value.trim()).displayName,
      });
  Future<void> signOut() => auth.signOut();
  void dispose() => api.close();
}
