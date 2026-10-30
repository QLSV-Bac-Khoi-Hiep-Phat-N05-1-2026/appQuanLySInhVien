import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/project_store.dart';
import '../ui/project_theme.dart';
import 'role_session_screen.dart';

class PendingAccountScreen extends StatefulWidget {
  const PendingAccountScreen({
    super.key,
    required this.auth,
    required this.profile,
  });
  final AuthService auth;
  final AppUser profile;
  @override
  State<PendingAccountScreen> createState() => _PendingAccountScreenState();
}

class _PendingAccountScreenState extends State<PendingAccountScreen> {
  late AppUser profile = widget.profile;
  bool busy = false, transferred = false;
  String? message;
  Future<void> _check() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final updated = await widget.auth.refreshProfile();
      if (!mounted) return;
      if (updated.isActive &&
          (!updated.isLecturer ||
              widget.auth.auth.currentUser!.emailVerified)) {
        transferred = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RoleSessionScreen(
              store: ProjectStore.cloud(widget.auth.data, widget.auth, updated),
            ),
          ),
        );
        return;
      }
      setState(() {
        profile = updated;
        message = widget.auth.auth.currentUser!.emailVerified
            ? 'Email đã xác minh. Hồ sơ hiện: ${updated.statusLabel}.'
            : 'Bạn cần mở thư xác minh email trước khi được duyệt.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Chưa kiểm tra được trạng thái. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _resend() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.auth.sendVerification();
      if (mounted) {
        setState(() => message = 'Đã gửi thư xác minh tới ${profile.email}.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Chưa gửi được thư. Kiểm tra mạng hoặc thử lại sau.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _logout() async {
    await widget.auth.signOut();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    if (!transferred) widget.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái tài khoản'),
        actions: [
          IconButton(
            onPressed: busy ? null : _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 50,
                    color: green,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile.statusLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(profile.email),
                  const SizedBox(height: 12),
                  const Text(
                    'Xác minh email rồi chờ Admin đối chiếu mã giảng viên và duyệt hồ sơ. Tài khoản chưa duyệt không được xem dữ liệu lớp.',
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        message!,
                        style: const TextStyle(color: green),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: busy ? null : _check,
                        child: Text(
                          busy ? 'Đang kiểm tra…' : 'Kiểm tra trạng thái',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : _resend,
                        child: const Text('Gửi lại email xác minh'),
                      ),
                    ],
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
