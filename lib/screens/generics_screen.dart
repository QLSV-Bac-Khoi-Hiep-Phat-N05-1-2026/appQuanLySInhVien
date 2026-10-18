import 'package:flutter/material.dart';

import '../models/student.dart';

class GenericsScreen extends StatelessWidget {
  const GenericsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = Student();
    final Object object = student;
    final Type classType = object.runtimeType;

    return Scaffold(
      appBar: AppBar(title: const Text('Thực hành Generics')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Student extends Genericclass<Object>\n\n'
          'Họ tên: ${student.getName()}\n'
          'Mã sinh viên: ${student.getStudentId()}\n'
          'Ngành: ${student.getMajor()}\n'
          'Tuổi: ${student.getAge()}\n\n'
          'Object là Student: ${object is Student}\n'
          'Type (runtimeType): $classType',
          style: const TextStyle(fontSize: 18, height: 1.6),
        ),
      ),
    );
  }
}
