import 'dart:async';

import '../models/app_user.dart';
import '../models/class_room.dart';
import '../models/grade.dart';
import '../models/student.dart';
import 'student_data_service.dart';

/// Queries match the access scope enforced by Firestore Rules, never client-side filtering alone.
class RoleDataSource {
  RoleDataSource({
    required this.data,
    required this.profile,
    required this.onStudents,
    required this.onClasses,
    required this.onGrades,
    required this.onUsers,
    required this.onError,
  });
  final StudentDataService data;
  final AppUser profile;
  final void Function(List<Student>) onStudents;
  final void Function(List<ClassRoom>) onClasses;
  final void Function(List<Grade>) onGrades;
  final void Function(List<AppUser>) onUsers;
  final void Function(Object) onError;
  final List<StreamSubscription<dynamic>> _base = [];
  final List<StreamSubscription<dynamic>> _studentSubs = [];
  final List<StreamSubscription<dynamic>> _gradeSubs = [];
  StreamSubscription<dynamic>? _classSub;
  int _classGeneration = 0, _gradeGeneration = 0;
  bool _closed = false;
  String _gradeScope = '';
  void start() {
    if (profile.isAdmin) {
      _base.add(data.students.watchAll().listen(onStudents, onError: onError));
      _base.add(data.classes.watchAll().listen(onClasses, onError: onError));
      _base.add(data.grades.watchAll().listen(onGrades, onError: onError));
      _base.add(
        data.firestore
            .collection('users')
            .where('role', whereIn: AppUser.roles)
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((doc) => AppUser.fromMap(doc.id, doc.data()))
                  .toList(),
            )
            .listen(onUsers, onError: onError),
      );
    } else if (profile.isLecturer) {
      _base.add(
        data.classes.collection
            .where('lecturerId', isEqualTo: profile.uid)
            .snapshots()
            .listen((snap) {
              final rooms = snap.docs.map((d) => d.data()).toList();
              onClasses(rooms);
              _watchClassStudents(rooms);
            }, onError: onError),
      );
    } else {
      final id = profile.studentId!;
      _base.add(
        data.students.collection.doc(id).snapshots().listen((doc) {
          final student = doc.data();
          if (student == null) {
            onError(StateError('Hồ sơ sinh viên liên kết không tồn tại.'));
            return;
          }
          onStudents([student]);
          _classSub?.cancel();
          if (student.classId == null) {
            onClasses([]);
          } else {
            _classSub = data.classes.collection
                .doc(student.classId)
                .snapshots()
                .listen((room) {
                  onClasses(room.data() == null ? [] : [room.data()!]);
                }, onError: onError);
          }
        }, onError: onError),
      );
      _base.add(
        data.watchGradesForStudent(id).listen(onGrades, onError: onError),
      );
    }
  }

  void _watchClassStudents(List<ClassRoom> rooms) {
    final generation = ++_classGeneration;
    for (final sub in _studentSubs) {
      sub.cancel();
    }
    _studentSubs.clear();
    onStudents([]);
    _watchGrades([]);
    if (rooms.isEmpty) return;
    final cache = <String, List<Student>>{};
    for (final room in rooms) {
      _studentSubs.add(
        data.watchStudentsInClass(room.id).listen((students) {
          if (_closed || generation != _classGeneration) return;
          cache[room.id] = students;
          if (cache.length == rooms.length) {
            final all = cache.values.expand((v) => v).toList();
            onStudents(all);
            _watchGrades(all.map((s) => s.studentId).toList());
          }
        }, onError: onError),
      );
    }
  }

  void _watchGrades(List<String> ids) {
    ids.sort();
    final scope = ids.join('|');
    if (scope == _gradeScope && _gradeSubs.isNotEmpty) return;
    _gradeScope = scope;
    final generation = ++_gradeGeneration;
    for (final sub in _gradeSubs) {
      sub.cancel();
    }
    _gradeSubs.clear();
    onGrades([]);
    if (ids.isEmpty) return;
    final cache = <String, List<Grade>>{};
    for (final id in ids) {
      _gradeSubs.add(
        data.watchGradesForStudent(id).listen((grades) {
          if (_closed || generation != _gradeGeneration) return;
          cache[id] = grades;
          if (cache.length == ids.length) {
            onGrades(cache.values.expand((v) => v).toList());
          }
        }, onError: onError),
      );
    }
  }

  void dispose() {
    _closed = true;
    _classSub?.cancel();
    for (final s in [..._base, ..._studentSubs, ..._gradeSubs]) {
      s.cancel();
    }
  }
}
