import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/student_data_service.dart';
import '../ui/project_theme.dart';
import 'pending_account_screen.dart';

class LecturerRegistrationScreen extends StatefulWidget {
  const LecturerRegistrationScreen({super.key});
  @override
  State<LecturerRegistrationScreen> createState() =>
      _LecturerRegistrationScreenState();
}

class _LecturerRegistrationScreenState
    extends State<LecturerRegistrationScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      code = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool busy = false;
  String? error;
  Future<void> _register() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final service = AuthService(
      auth: FirebaseAuth.instance,
      data: StudentDataService(FirebaseFirestore.instance),
    );
    try {
      final profile = await service.registerLecturer(
        email: email.text,
        password: password.text,
        name: name.text,
        lecturerCode: code.text,
      );
      if (!mounted) {
        await service.signOut();
        service.dispose();
        return;
      }
      password.clear();
      confirm.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PendingAccountScreen(auth: service, profile: profile),
        ),
      );
    } catch (e) {
      service.dispose();
      if (mounted) {
        setState(() {
          busy = false;
          error = e is StateError
              ? e.message.toString()
              : 'Không đăng ký được. Kiểm tra thông tin và kết nối.';
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [name, code, email, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Đăng ký giảng viên')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đăng ký để được xét duyệt',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chỉ dành cho giảng viên. Xác minh email không tự cấp quyền; Admin sẽ đối chiếu và duyệt hồ sơ.',
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: name,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên giảng viên',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty || v.length > 150
                        ? 'Nhập họ tên hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: code,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Mã giảng viên',
                    ),
                    validator: (v) =>
                        RegExp(r'^[A-Za-z0-9_-]{1,80}$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Nhập mã giảng viên hợp lệ',
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email thật để xác minh',
                    ),
                    validator: (v) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v?.trim() ?? '')
                        ? null
                        : 'Nhập email hợp lệ',
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: password,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu ứng dụng',
                    ),
                    validator: (v) =>
                        v == null || v.length < 8 || v.length > 128
                        ? 'Mật khẩu cần 8–128 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: confirm,
                    enabled: !busy,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                    ),
                    validator: (v) =>
                        v != password.text ? 'Mật khẩu chưa khớp' : null,
                  ),
                  const SizedBox(height: 18),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : _register,
                      child: Text(busy ? 'Đang đăng ký…' : 'Gửi hồ sơ đăng ký'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
