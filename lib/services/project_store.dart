import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/class_room.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import 'auth_service.dart';
import 'role_data_source.dart';
import 'student_data_service.dart';

class ProjectStore extends ChangeNotifier {
  ProjectStore.demo({this.persist = true, String role = 'admin'})
    : data = null,
      auth = null,
      _selectedRole = role;
  ProjectStore.cloud(this.data, this.auth, this.profile)
    : persist = false,
      _selectedRole = profile.role;
  static const storageKey = 'qlsv.roles.v2';
  final StudentDataService? data;
  final AuthService? auth;
  final bool persist;
  final String _selectedRole;
  bool get isDemo => data == null;
  AppUser profile = AppUser(
    uid: 'demo-admin',
    email: 'admin.demo@example.invalid',
    displayName: 'Nguyễn Văn Bắc',
  );
  List<Student> _allStudents = [];
  List<ClassRoom> _allClasses = [];
  List<Subject> _allSubjects = [];
  List<Grade> _allGrades = [];
  List<AppUser> _users = [];
  List<ClassRoom> get classes => profile.isAdmin
      ? _allClasses
      : _allClasses
            .where(
              (c) => profile.isLecturer
                  ? c.lecturerId == profile.uid
                  : _allStudents.any(
                      (s) =>
                          s.studentId == profile.studentId && s.classId == c.id,
                    ),
            )
            .toList();
  List<Student> get students => profile.isAdmin
      ? _allStudents
      : _allStudents
            .where(
              (s) => profile.isStudent
                  ? s.studentId == profile.studentId
                  : classes.any((c) => c.id == s.classId),
            )
            .toList();
  List<Subject> get subjects => _allSubjects;
  List<Grade> get grades => profile.isAdmin
      ? _allGrades
      : _allGrades
            .where(
              (g) => profile.isStudent
                  ? g.studentId == profile.studentId
                  : students.any((s) => s.studentId == g.studentId),
            )
            .toList();
  List<AppUser> get users => profile.isAdmin ? _users : [profile];
  List<AppUser> get activeLecturers =>
      _users.where((u) => u.isLecturer && u.isActive).toList();
  Student? get myStudent =>
      students.where((s) => s.studentId == profile.studentId).firstOrNull;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  RoleDataSource? _source;
  bool loading = true;
  String? error;
  bool _disposed = false;
  final List<String> activities = [];

  Future<void> initialize() async {
    try {
      if (isDemo) {
        if (!AppUser.roles.contains(_selectedRole)) {
          throw StateError('Vai trò demo không hợp lệ.');
        }
        final prefs = persist ? await SharedPreferences.getInstance() : null;
        final saved = prefs?.getString(storageKey);
        if (saved == null) {
          _seed();
          _seedUsers();
          final legacy = prefs?.getString('qlsv.presentation.v1');
          if (legacy != null) {
            final map = jsonDecode(legacy) as Map<String, dynamic>;
            _allStudents = _decode(map['students'], Student.fromMap);
            _allClasses = _decode(map['classes'], ClassRoom.fromMap);
            _allSubjects = _decode(map['subjects'], Subject.fromMap);
            _allGrades = _decode(map['grades'], Grade.fromMap);
            _allClasses = _allClasses
                .map(
                  (c) => ClassRoom(
                    id: c.id,
                    name: c.name,
                    major: c.major,
                    cohort: c.cohort,
                    lecturerId:
                        c.lecturerId ??
                        (c.id == 'CNTT01' ? 'demo-lecturer' : null),
                    lecturerName:
                        c.lecturerName ??
                        (c.id == 'CNTT01' ? 'Giảng viên mẫu' : null),
                  ),
                )
                .toList();
            final at = _allStudents.indexWhere((s) => s.studentId == 'SV001');
            if (at >= 0) {
              _allStudents[at] = _allStudents[at].withAccount('demo-student');
            }
            final oldName = (map['profile'] as Map?)?['displayName'];
            if (oldName is String && oldName.trim().isNotEmpty) {
              _users[0] = _users[0].copyWith(displayName: oldName);
            }
          }
        } else {
          final map = jsonDecode(saved) as Map<String, dynamic>;
          _allStudents = _decode(map['students'], Student.fromMap);
          _allClasses = _decode(map['classes'], ClassRoom.fromMap);
          _allSubjects = _decode(map['subjects'], Subject.fromMap);
          _allGrades = _decode(map['grades'], Grade.fromMap);
          _users = _decode(map['users'], AppUser.fromMap);
        }
        profile = _users.firstWhere(
          (u) => u.role == _selectedRole && u.isActive,
        );
        await _persist();
        loading = false;
      } else {
        if (!profile.isActive) {
          throw StateError('Tài khoản chưa được kích hoạt.');
        }
        final received = <String>{};
        void ready(String kind) {
          received.add(kind);
          if (received.length >= 4) loading = false;
          _changed();
        }

        _source = RoleDataSource(
          data: data!,
          profile: profile,
          onStudents: (v) {
            _allStudents = v;
            ready('students');
          },
          onClasses: (v) {
            _allClasses = v;
            ready('classes');
          },
          onGrades: (v) {
            _allGrades = v;
            ready('grades');
          },
          onUsers: (v) {
            _users = v;
            _changed();
          },
          onError: _loadError,
        );
        _source!.start();
        _subscriptions.add(
          data!.subjects.watchAll().listen((v) {
            _allSubjects = v;
            ready('subjects');
          }, onError: _loadError),
        );
        _subscriptions.add(
          data!.users.collection.doc(profile.uid).snapshots().listen((doc) {
            final current = doc.data();
            if (current == null ||
                !current.isActive ||
                current.role != profile.role ||
                current.studentId != profile.studentId) {
              _source?.dispose();
              _allStudents = [];
              _allClasses = [];
              _allGrades = [];
              _allSubjects = [];
              _users = [];
              _loadError(
                StateError(
                  'Quyền tài khoản đã thay đổi. Vui lòng đăng nhập lại.',
                ),
              );
              return;
            }
            profile = current;
            _changed();
          }, onError: _loadError),
        );
      }
    } catch (e) {
      loading = false;
      error = e is StateError
          ? e.message.toString()
          : 'Không tải được dữ liệu. Kiểm tra kết nối hoặc liên hệ Admin.';
    }
    _changed();
  }

  List<T> _decode<T>(
    dynamic rows,
    T Function(String, Map<String, dynamic>) from,
  ) => (rows as List)
      .map((r) => from(r['id'] as String, Map<String, dynamic>.from(r['data'])))
      .toList();
  void _seedUsers() {
    _users = [
      profile,
      AppUser(
        uid: 'demo-lecturer',
        email: 'lecturer.demo@example.invalid',
        displayName: 'Giảng viên mẫu',
        role: 'lecturer',
        lecturerCode: 'GV001',
      ),
      AppUser(
        uid: 'demo-student',
        email: 'student.demo@example.invalid',
        displayName: 'Sinh viên Mẫu 01',
        role: 'student',
        studentId: 'SV001',
      ),
      AppUser(
        uid: 'demo-pending',
        email: 'pending.demo@example.invalid',
        displayName: 'Giảng viên chờ duyệt mẫu',
        role: 'lecturer',
        status: 'pending',
        lecturerCode: 'GV002',
      ),
      AppUser(
        uid: 'demo-other-lecturer',
        email: 'other.demo@example.invalid',
        displayName: 'Giảng viên lớp khác',
        role: 'lecturer',
        lecturerCode: 'GV003',
      ),
    ];
  }

  void _seed() {
    _allClasses = [
      ClassRoom(
        id: 'CNTT01',
        name: 'Công nghệ thông tin 01',
        major: 'Công nghệ thông tin',
        cohort: 'K17',
        lecturerId: 'demo-lecturer',
        lecturerName: 'Giảng viên mẫu',
      ),
      ClassRoom(
        id: 'CNTT02',
        name: 'Công nghệ thông tin 02',
        major: 'Công nghệ thông tin',
        cohort: 'K17',
        lecturerId: 'demo-other-lecturer',
        lecturerName: 'Giảng viên lớp khác',
      ),
      ClassRoom(
        id: 'KT01',
        name: 'Kế toán 01',
        major: 'Kế toán',
        cohort: 'K18',
      ),
    ];
    const names = [
      'Sinh viên Mẫu 01',
      'Sinh viên Mẫu 02',
      'Sinh viên Mẫu 03',
      'Sinh viên Mẫu 04',
      'Sinh viên Mẫu 05',
      'Sinh viên Mẫu 06',
      'Sinh viên Mẫu 07',
      'Sinh viên Mẫu 08',
    ];
    _allStudents = List.generate(
      names.length,
      (i) => Student(
        studentId: 'SV00${i + 1}',
        name: names[i],
        age: 20 + i % 3,
        major: i == 6 ? 'Kế toán' : 'Công nghệ thông tin',
        classId: i == 7
            ? null
            : (i == 6
                  ? 'KT01'
                  : i < 4
                  ? 'CNTT01'
                  : 'CNTT02'),
        email: 'sv00${i + 1}@example.invalid',
        accountUid: i == 0 ? 'demo-student' : null,
      ),
    );
    _allSubjects = [
      Subject(id: 'MOB01', name: 'Lập trình di động', credits: 3),
      Subject(id: 'WEB01', name: 'Lập trình Web nâng cao', credits: 3),
      Subject(id: 'CSDL01', name: 'Cơ sở dữ liệu', credits: 3),
      Subject(id: 'CTDL01', name: 'Cấu trúc dữ liệu và giải thuật', credits: 4),
    ];
    _allGrades = List.generate(
      10,
      (i) => Grade(
        studentId: 'SV00${i % 5 + 1}',
        subjectId: i < 5 ? 'MOB01' : 'CSDL01',
        semester: '2026-1',
        score: [8.5, 7.0, 9.0, 6.5, 8.0][i % 5],
      ),
    );
  }

  Future<void> _persist() async {
    if (!isDemo || !persist) return;
    final value = jsonEncode({
      'students': _allStudents
          .map((v) => {'id': v.studentId, 'data': v.toMap()})
          .toList(),
      'classes': _allClasses
          .map((v) => {'id': v.id, 'data': v.toMap()})
          .toList(),
      'subjects': _allSubjects
          .map((v) => {'id': v.id, 'data': v.toMap()})
          .toList(),
      'grades': _allGrades.map((v) => {'id': v.id, 'data': v.toMap()}).toList(),
      'users': _users.map((v) => {'id': v.uid, 'data': v.toMap()}).toList(),
    });
    if (!await (await SharedPreferences.getInstance()).setString(
      storageKey,
      value,
    )) {
      throw StateError('Không lưu được dữ liệu trên máy.');
    }
  }

  void _active() {
    if (!profile.isActive || error != null) {
      throw StateError('Phiên làm việc không còn quyền truy cập.');
    }
  }

  void _admin() {
    _active();
    if (!profile.isAdmin) {
      throw StateError('Chỉ Admin được thực hiện thao tác này.');
    }
  }

  bool _owns(String? classId) =>
      classId != null &&
      _allClasses.any((c) => c.id == classId && c.lecturerId == profile.uid);
  void _manage(Student student) {
    _active();
    if (!profile.isAdmin && !(profile.isLecturer && _owns(student.classId))) {
      throw StateError('Sinh viên không thuộc lớp được phân công.');
    }
  }

  Future<void> _change(Future<void> Function() action, String message) async {
    _active();
    final oldStudents = List<Student>.of(_allStudents),
        oldClasses = List<ClassRoom>.of(_allClasses),
        oldSubjects = List<Subject>.of(_allSubjects),
        oldGrades = List<Grade>.of(_allGrades),
        oldUsers = List<AppUser>.of(_users);
    final oldProfile = profile;
    try {
      await action();
      await _persist();
    } catch (_) {
      _allStudents = oldStudents;
      _allClasses = oldClasses;
      _allSubjects = oldSubjects;
      _allGrades = oldGrades;
      _users = oldUsers;
      profile = oldProfile;
      rethrow;
    }
    activities.insert(0, message);
    _changed();
  }

  Future<void> saveStudent(
    Student value, {
    bool editing = false,
  }) => _change(() async {
    value.validate();
    _manage(value);
    if (value.classId != null && !_allClasses.any((c) => c.id == value.classId)) {
      throw StateError('Lớp được chọn không tồn tại.');
    }
    final at = _allStudents.indexWhere((v) => v.studentId == value.studentId);
    if (!editing && at >= 0) throw StateError('Mã sinh viên đã tồn tại.');
    if (editing && at < 0) throw StateError('Sinh viên không còn tồn tại.');
    var student = value;
    if (editing) {
      _manage(_allStudents[at]);
      final uid = _allStudents[at].accountUid;
      if (uid != null) student = value.withAccount(uid);
    }
    if (isDemo) {
      if (editing) {
        _allStudents[at] = student;
      } else {
        _allStudents.add(student);
      }
    } else if (editing) {
      await data!.students.update(student);
    } else {
      await data!.createStudent(student);
    }
  }, '${editing ? 'Cập nhật' : 'Thêm'} sinh viên ${value.studentId}');
  Future<void> deleteStudent(String id) => _change(() async {
    final student = _allStudents.where((s) => s.studentId == id).firstOrNull;
    if (student == null) throw StateError('Sinh viên không tồn tại.');
    _manage(student);
    if (!isDemo) {
      throw StateError(
        'Xóa cloud đang khóa để bảo vệ ràng buộc điểm/tài khoản.',
      );
    }
    if (_allGrades.any((g) => g.studentId == id) || student.accountUid != null) {
      throw StateError(
        'Sinh viên đã có điểm hoặc tài khoản. Không thể xóa hồ sơ.',
      );
    }
    _allStudents.removeWhere((s) => s.studentId == id);
  }, 'Xóa sinh viên $id');
  Future<void> saveClass(ClassRoom room, {bool editing = false}) =>
      _change(() async {
        final at = _allClasses.indexWhere((v) => v.id == room.id);
        if (!editing) {
          _admin();
          if (at >= 0) throw StateError('Mã lớp đã tồn tại.');
        } else {
          if (at < 0) throw StateError('Lớp không tồn tại.');
          if (!profile.isAdmin && !(profile.isLecturer && _owns(room.id))) {
            throw StateError('Lớp không được phân công cho bạn.');
          }
        }
        final old = at >= 0 ? _allClasses[at] : null;
        final value = ClassRoom(
          id: room.id,
          name: room.name,
          major: room.major,
          cohort: room.cohort,
          lecturerId: old?.lecturerId,
          lecturerName: old?.lecturerName,
        );
        if (isDemo) {
          if (editing) {
            _allClasses[at] = value;
          } else {
            _allClasses.add(value);
          }
        } else if (editing) {
          await data!.classes.update(value);
        } else {
          await data!.classes.create(value);
        }
      }, '${editing ? 'Cập nhật' : 'Thêm'} lớp ${room.id}');
  Future<void> saveSubject(Subject subject) => _change(() async {
    _admin();
    if (_allSubjects.any((v) => v.id == subject.id)) {
      throw StateError('Mã môn học đã tồn tại.');
    }
    if (isDemo) {
      _allSubjects.add(subject);
    } else {
      await data!.subjects.create(subject);
    }
  }, 'Thêm môn ${subject.id}');
  Future<void> saveGrade(Grade grade) => _change(() async {
    final student = _allStudents
        .where((s) => s.studentId == grade.studentId)
        .firstOrNull;
    if (student == null || !_allSubjects.any((s) => s.id == grade.subjectId)) {
      throw StateError('Sinh viên hoặc môn học không tồn tại.');
    }
    _manage(student);
    if (isDemo) {
      final at = _allGrades.indexWhere((g) => g.id == grade.id);
      if (at < 0) {
        _allGrades.add(grade);
      } else {
        _allGrades[at] = grade;
      }
    } else {
      await data!.saveGrade(grade);
    }
  }, 'Lưu điểm ${grade.studentId} · ${grade.subjectId}');
  Future<void> updateName(String value) => _change(() async {
    if (profile.isStudent) {
      throw StateError('Họ tên chính thức do giảng viên/Admin quản lý.');
    }
    final updated = profile.copyWith(displayName: value.trim());
    if (!isDemo) await auth!.updateDisplayName(profile, updated.displayName);
    profile = updated;
    _replaceUser(updated);
  }, 'Cập nhật họ tên');
  Future<void> updateContact(String phone, String email, String address) =>
      _change(() async {
        final updated = profile.copyWith(
          phone: phone.trim(),
          contactEmail: email.trim(),
          address: address.trim(),
        );
        if (!isDemo) {
          await data!.users.collection.doc(profile.uid).update({
            'phone': updated.phone,
            'contactEmail': updated.contactEmail,
            'address': updated.address,
          });
        }
        profile = updated;
        _replaceUser(updated);
      }, 'Cập nhật thông tin liên hệ');
  void _replaceUser(AppUser user) {
    final at = _users.indexWhere((u) => u.uid == user.uid);
    if (at < 0) {
      _users.add(user);
    } else {
      _users[at] = user;
    }
  }

  Future<void> decideLecturer(String uid, bool approve) => _change(() async {
    _admin();
    if (isDemo) {
      final u = _users.firstWhere((u) => u.uid == uid);
      if (!u.isLecturer || u.status != 'pending') {
        throw StateError('Hồ sơ không còn chờ duyệt.');
      }
      _replaceUser(u.copyWith(status: approve ? 'active' : 'rejected'));
    } else {
      await auth!.api.call('/lecturers/${Uri.encodeComponent(uid)}/decision', {
        'decision': approve ? 'approve' : 'reject',
      });
    }
  }, '${approve ? 'Duyệt' : 'Từ chối'} hồ sơ giảng viên');
  Future<void> assignLecturer(String classId, String uid) => _change(() async {
    _admin();
    if (isDemo) {
      final lecturer = _users.firstWhere((u) => u.uid == uid);
      if (!lecturer.isLecturer || !lecturer.isActive) {
        throw StateError('Giảng viên chưa hoạt động.');
      }
      final at = _allClasses.indexWhere((c) => c.id == classId);
      if (at < 0) throw StateError('Lớp không tồn tại.');
      final c = _allClasses[at];
      _allClasses[at] = ClassRoom(
        id: c.id,
        name: c.name,
        major: c.major,
        cohort: c.cohort,
        lecturerId: uid,
        lecturerName: lecturer.displayName,
      );
    } else {
      await auth!.api.call(
        '/classes/${Uri.encodeComponent(classId)}/lecturer',
        {'lecturerId': uid},
      );
    }
  }, 'Phân công giảng viên cho lớp $classId');
  Future<void> changeAccountStatus(String uid, String status) =>
      _change(() async {
        _admin();
        if (uid == profile.uid || !['active', 'suspended'].contains(status)) {
          throw StateError('Thao tác trạng thái không hợp lệ.');
        }
        if (isDemo) {
          final u = _users.firstWhere((u) => u.uid == uid);
          if (u.isAdmin || ['pending', 'rejected'].contains(u.status)) {
            throw StateError('Không thể đổi trạng thái tài khoản này.');
          }
          _replaceUser(u.copyWith(status: status));
        } else {
          await auth!.api.call('/users/${Uri.encodeComponent(uid)}/status', {
            'status': status,
          });
        }
      }, 'Cập nhật trạng thái tài khoản');
  Future<String> provisionStudent(String id, String email) async {
    String message = '';
    await _change(() async {
      final student = _allStudents.where((s) => s.studentId == id).firstOrNull;
      if (student == null) throw StateError('Sinh viên không tồn tại.');
      _manage(student);
      if (isDemo) {
        final other = _users
            .where(
              (u) =>
                  u.email.toLowerCase() == email.trim().toLowerCase() &&
                  u.studentId != id,
            )
            .firstOrNull;
        if (other != null) {
          throw StateError('Email đã được dùng cho tài khoản khác.');
        }
        final uid = student.accountUid ?? 'demo-student-$id';
        final current = _users.where((u) => u.uid == uid).firstOrNull;
        if (current != null &&
            current.email.toLowerCase() != email.trim().toLowerCase()) {
          throw StateError('Sinh viên đã liên kết email khác.');
        }
        final user = AppUser(
          uid: uid,
          email: email.trim().toLowerCase(),
          displayName: student.name,
          role: 'student',
          studentId: id,
        );
        _replaceUser(user);
        _allStudents[_allStudents.indexWhere((s) => s.studentId == id)] =
            student.withAccount(uid);
        message = 'Đã cấp tài khoản demo. Không gửi email thật.';
      } else {
        final result = await auth!.api.call('/students/provision', {
          'studentId': id,
          'email': email.trim(),
        });
        message = result['invitationSent'] == true
            ? 'Đã cấp tài khoản và gửi email đặt mật khẩu.'
            : 'Tài khoản đã tạo, nhưng email chưa gửi được. Có thể gửi lại.';
      }
    }, 'Cấp tài khoản sinh viên $id');
    return message;
  }

  Future<void> requestPasswordReset() async {
    _active();
    if (isDemo) throw StateError('Chế độ demo không gửi email thật.');
    await auth!.resetPassword(profile.email);
  }

  String className(String? id) =>
      classes.where((c) => c.id == id).firstOrNull?.name ?? 'Chưa xếp lớp';
  String subjectName(String id) =>
      subjects.where((s) => s.id == id).firstOrNull?.name ?? id;
  double? averageFor(String id) {
    final rows = grades.where((g) => g.studentId == id).toList();
    if (rows.isEmpty) return null;
    double total = 0;
    int count = 0;
    for (final g in rows) {
      final weight =
          subjects.where((s) => s.id == g.subjectId).firstOrNull?.credits ?? 1;
      total += g.score * weight;
      count += weight;
    }
    return total / count;
  }

  void _loadError(Object e) {
    loading = false;
    error = e is StateError
        ? e.message.toString()
        : 'Không tải được dữ liệu. Kiểm tra kết nối và quyền truy cập.';
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _source?.dispose();
    for (final s in _subscriptions) {
      s.cancel();
    }
    auth?.dispose();
    super.dispose();
  }
}
