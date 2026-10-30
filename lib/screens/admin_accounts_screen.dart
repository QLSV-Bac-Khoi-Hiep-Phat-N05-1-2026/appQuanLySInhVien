import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/project_store.dart';
import '../ui/project_theme.dart';

class AdminAccountsScreen extends StatelessWidget {
  const AdminAccountsScreen({super.key, required this.store});
  final ProjectStore store;
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật tài khoản.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? e.message.toString()
                  : 'Không thực hiện được yêu cầu.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _decision(
    BuildContext context,
    AppUser user,
    bool approve,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(approve ? 'Duyệt giảng viên?' : 'Từ chối hồ sơ?'),
        content: Text(
          approve
              ? 'Xác nhận đã đối chiếu ${user.displayName}, mã ${user.lecturerCode} và email ${user.email} với thông tin giảng viên. Backend sẽ kiểm tra email đã được xác minh.'
              : 'Từ chối hồ sơ của ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(context, () => store.decideLecturer(user.uid, approve));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!store.profile.isAdmin) {
      return const EmptyState(
        title: 'Không có quyền truy cập',
        message: 'Chỉ Admin được quản lý tài khoản.',
      );
    }
    final pending = store.users
        .where((u) => u.isLecturer && u.status == 'pending')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản trị tài khoản',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Duyệt đúng giảng viên trước khi phân công lớp. Sinh viên được cấp tài khoản từ hồ sơ học vụ.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giảng viên chờ duyệt (${pending.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              if (pending.isEmpty)
                const Text(
                  'Không có hồ sơ đang chờ.',
                  style: TextStyle(color: muted),
                ),
              for (final u in pending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${u.lecturerCode} · ${u.email}',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: () => _decision(context, u, true),
                            child: const Text('Duyệt giảng viên'),
                          ),
                          OutlinedButton(
                            onPressed: () => _decision(context, u, false),
                            child: const Text('Từ chối'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản trong hệ thống',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final u in store.users)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE6F4ED),
                        child: Icon(
                          u.isAdmin
                              ? Icons.admin_panel_settings
                              : u.isLecturer
                              ? Icons.school
                              : Icons.person,
                          color: green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              u.email,
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                            Text(
                              '${u.roleLabel} · ${u.statusLabel}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!u.isAdmin &&
                          !['pending', 'rejected'].contains(u.status))
                        IconButton(
                          tooltip: u.isActive
                              ? 'Khóa tài khoản'
                              : 'Mở khóa tài khoản',
                          onPressed: () => _run(
                            context,
                            () => store.changeAccountStatus(
                              u.uid,
                              u.isActive ? 'suspended' : 'active',
                            ),
                          ),
                          icon: Icon(
                            u.isActive ? Icons.lock_outline : Icons.lock_open,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
