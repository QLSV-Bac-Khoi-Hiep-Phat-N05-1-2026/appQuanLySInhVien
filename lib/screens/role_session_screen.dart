import 'dart:async';

import 'package:flutter/material.dart';

import '../services/project_store.dart';
import '../ui/project_theme.dart';
import 'student_portal_screen.dart';
import 'project_workspace.dart';

class RoleSessionScreen extends StatefulWidget {
  const RoleSessionScreen({super.key, required this.store});
  final ProjectStore store;
  @override
  State<RoleSessionScreen> createState() => _RoleSessionScreenState();
}

class _RoleSessionScreenState extends State<RoleSessionScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.initialize());
  }

  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await widget.store.auth?.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final s = widget.store;
      if (s.loading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (s.error != null) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 45, color: muted),
                      const SizedBox(height: 18),
                      Text(s.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _logout,
                        child: const Text('Về đăng nhập'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
      if (s.profile.isStudent) {
        return StudentSessionScreen(store: s, onSignOut: _logout);
      }
      return ProjectWorkspace(store: s);
    },
  );
}

/// Connects the student portal to the authorized session data and actions.
class StudentSessionScreen extends StatelessWidget {
  const StudentSessionScreen({
    super.key,
    required this.store,
    required this.onSignOut,
  });
  final ProjectStore store;
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context) {
    final student = store.myStudent;
    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cổng sinh viên')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chưa có hồ sơ sinh viên được liên kết.'),
              TextButton(onPressed: onSignOut, child: const Text('Đăng xuất')),
            ],
          ),
        ),
      );
    }
    final profile = store.profile;
    return PopScope(
      canPop: false,
      child: StudentPortalScreen(
        key: ValueKey(profile.uid),
        student: student,
        classRoom: store.classes
            .where((room) => room.id == student.classId)
            .firstOrNull,
        grades: store.grades,
        subjects: store.subjects,
        loginEmail: profile.email,
        phone: profile.phone,
        contactEmail: profile.contactEmail,
        address: profile.address,
        onSaveContact: store.updateContact,
        onRequestPasswordReset: store.requestPasswordReset,
        onSignOut: onSignOut,
      ),
    );
  }
}
