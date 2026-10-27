import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'student_data_service.dart';

/// Accounts are created/provisioned by the Firebase project owner.
class AuthService {
  final FirebaseAuth auth;
  final StudentDataService data;

  AuthService({required this.auth, required this.data});

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
      if (profile == null || profile.role != 'manager') {
        throw StateError('Tài khoản chưa được cấp quyền quản lý.');
      }
      return profile;
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  Future<void> updateDisplayName(AppUser user, String displayName) =>
      data.users.update(
        AppUser(
          uid: user.uid,
          email: user.email,
          role: user.role,
          displayName: displayName.trim(),
        ),
      );

  Future<void> signOut() => auth.signOut();
}
