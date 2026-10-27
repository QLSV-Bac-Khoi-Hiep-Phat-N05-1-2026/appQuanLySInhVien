import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/class_room.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import 'firestore_repository.dart';

/// One shared entry point for all four members. Inject Firestore in tests.
/// References are checked again by Firestore rules on the server.
class StudentDataService {
  final FirebaseFirestore firestore;
  late final users = FirestoreRepository<AppUser>(
    firestore: firestore,
    path: 'users',
    decode: AppUser.fromMap,
    encode: (user) => user.toMap(),
    idOf: (user) => user.uid,
  );
  late final students = FirestoreRepository<Student>(
    firestore: firestore,
    path: 'students',
    decode: Student.fromMap,
    encode: (student) => student.toMap(),
    idOf: (student) => student.studentId,
  );
  late final classes = FirestoreRepository<ClassRoom>(
    firestore: firestore,
    path: 'classes',
    decode: ClassRoom.fromMap,
    encode: (room) => room.toMap(),
    idOf: (room) => room.id,
  );
  late final subjects = FirestoreRepository<Subject>(
    firestore: firestore,
    path: 'subjects',
    decode: Subject.fromMap,
    encode: (subject) => subject.toMap(),
    idOf: (subject) => subject.id,
  );
  late final grades = FirestoreRepository<Grade>(
    firestore: firestore,
    path: 'grades',
    decode: Grade.fromMap,
    encode: (grade) => grade.toMap(),
    idOf: (grade) => grade.id,
  );

  StudentDataService(this.firestore);

  Stream<List<Student>> watchStudentsInClass(String classId) => students
      .collection
      .where('classId', isEqualTo: classId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Stream<List<Grade>> watchGradesForStudent(String studentId) => grades
      .collection
      .where('studentId', isEqualTo: studentId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  Future<void> createStudent(Student student) async {
    student.validate();
    final ref = students.collection.doc(student.studentId);
    await firestore.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        throw StateError('Mã sinh viên đã tồn tại.');
      }
      if (student.classId != null &&
          !(await transaction.get(classes.collection.doc(student.classId)))
              .exists) {
        throw StateError('Lớp học không tồn tại.');
      }
      transaction.set(ref, student);
    });
  }

  Future<void> saveGrade(Grade grade) async {
    await firestore.runTransaction((transaction) async {
      final student = await transaction.get(
        students.collection.doc(grade.studentId),
      );
      final subject = await transaction.get(
        subjects.collection.doc(grade.subjectId),
      );
      if (!student.exists || !subject.exists) {
        throw StateError('Sinh viên hoặc môn học không tồn tại.');
      }
      transaction.set(grades.collection.doc(grade.id), grade);
    });
  }
}
