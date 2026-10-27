import 'model_validation.dart';

/// Profile only. Passwords and authentication are managed by Firebase Auth.
/// The manager role is provisioned by the project owner, never by the client.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'manager',
  }) {
    ModelValidation.text(uid, 'uid', max: 128);
    if (uid.contains('/')) throw const FormatException('uid không hợp lệ.');
    ModelValidation.email(email);
    ModelValidation.text(displayName, 'Họ tên');
    if (role != 'manager') {
      throw const FormatException('Vai trò chưa được hỗ trợ.');
    }
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) => AppUser(
    uid: id,
    email: ModelValidation.string(data, 'email'),
    displayName: ModelValidation.string(data, 'displayName'),
    role: ModelValidation.string(data, 'role'),
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'role': role,
  };
}
