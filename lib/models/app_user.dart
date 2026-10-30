import 'model_validation.dart';

class AppUser {
  static const roles = ['admin', 'lecturer', 'student'];
  static const statuses = ['active', 'pending', 'rejected', 'suspended'];
  final String uid, email, displayName, role, status;
  final String? studentId;
  final String lecturerCode, phone, contactEmail, address;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'admin',
    this.status = 'active',
    this.studentId,
    this.lecturerCode = '',
    this.phone = '',
    this.contactEmail = '',
    this.address = '',
  }) {
    ModelValidation.text(uid, 'uid', max: 128);
    if (uid.contains('/')) throw const FormatException('uid không hợp lệ.');
    ModelValidation.email(email);
    ModelValidation.text(displayName, 'Họ tên');
    if (!roles.contains(role) || !statuses.contains(status)) {
      throw const FormatException(
        'Tài khoản chưa có vai trò/trạng thái hợp lệ. Liên hệ quản trị viên.',
      );
    }
    if (role == 'student' && studentId == null) {
      throw const FormatException('Thiếu mã sinh viên liên kết.');
    }
    if (studentId != null) ModelValidation.id(studentId!, 'Mã sinh viên');
    if (phone.isNotEmpty && !RegExp(r'^[+0-9 ()-]{8,20}$').hasMatch(phone)) {
      throw const FormatException('Số điện thoại không hợp lệ.');
    }
    ModelValidation.email(contactEmail, optional: true);
    if (address.length > 300 || lecturerCode.length > 80) {
      throw const FormatException('Thông tin liên hệ/mã giảng viên quá dài.');
    }
  }
  bool get isAdmin => role == 'admin';
  bool get isLecturer => role == 'lecturer';
  bool get isStudent => role == 'student';
  bool get isActive => status == 'active';
  String get roleLabel => switch (role) {
    'admin' => 'Quản trị viên',
    'lecturer' => 'Giảng viên',
    _ => 'Sinh viên',
  };
  String get statusLabel => switch (status) {
    'pending' => 'Chờ duyệt',
    'rejected' => 'Từ chối',
    'suspended' => 'Đã khóa',
    _ => 'Hoạt động',
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> d) => AppUser(
    uid: id,
    email: ModelValidation.string(d, 'email'),
    displayName: ModelValidation.string(d, 'displayName'),
    role: ModelValidation.string(d, 'role'),
    status: d['status'] as String? ?? 'active',
    studentId: d['studentId'] as String?,
    lecturerCode: d['lecturerCode'] as String? ?? '',
    phone: d['phone'] as String? ?? '',
    contactEmail: d['contactEmail'] as String? ?? '',
    address: d['address'] as String? ?? '',
  );
  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'role': role,
    'status': status,
    'studentId': studentId,
    'lecturerCode': lecturerCode,
    'phone': phone,
    'contactEmail': contactEmail,
    'address': address,
  };
  AppUser copyWith({
    String? displayName,
    String? status,
    String? phone,
    String? contactEmail,
    String? address,
  }) => AppUser(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    role: role,
    status: status ?? this.status,
    studentId: studentId,
    lecturerCode: lecturerCode,
    phone: phone ?? this.phone,
    contactEmail: contactEmail ?? this.contactEmail,
    address: address ?? this.address,
  );
}
