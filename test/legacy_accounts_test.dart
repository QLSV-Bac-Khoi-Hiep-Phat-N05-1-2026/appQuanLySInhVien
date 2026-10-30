import 'package:app_quan_ly_sinh_vien/models/app_user.dart';
import 'package:app_quan_ly_sinh_vien/services/role_data_source.dart';
import 'package:app_quan_ly_sinh_vien/services/student_data_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Admin account stream excludes legacy manager documents without granting roles', () async {
    final db = FakeFirebaseFirestore();
    final admin = AppUser(
      uid: 'admin',
      email: 'admin@example.test',
      displayName: 'Admin',
    );
    await db.doc('users/admin').set(admin.toMap());
    await db.doc('users/legacy').set({
      'role': 'manager',
      'email': 'legacy@example.test',
    });
    final errors = <Object>[];
    final received = <List<AppUser>>[];
    final source = RoleDataSource(
      data: StudentDataService(db),
      profile: admin,
      onStudents: (_) {},
      onClasses: (_) {},
      onGrades: (_) {},
      onUsers: received.add,
      onError: errors.add,
    );
    source.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(errors, isEmpty);
    expect(received.last.map((user) => user.uid), ['admin']);
    expect((await db.doc('users/legacy').get()).data()!['role'], 'manager');
    source.dispose();
  });
}
