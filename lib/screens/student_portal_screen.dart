import 'package:flutter/material.dart';

import '../models/class_room.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../ui/project_theme.dart';

class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({
    super.key,
    required this.student,
    required this.classRoom,
    required this.grades,
    required this.subjects,
    required this.loginEmail,
    this.phone = '',
    this.contactEmail = '',
    this.address = '',
    required this.onSaveContact,
    required this.onRequestPasswordReset,
    required this.onSignOut,
  });

  final Student student;
  final ClassRoom? classRoom;
  final List<Grade> grades;
  final List<Subject> subjects;
  final String loginEmail;
  final String phone;
  final String contactEmail;
  final String address;
  final Future<void> Function(String phone, String contactEmail, String address)
  onSaveContact;
  final Future<void> Function() onRequestPasswordReset;
  final Future<void> Function() onSignOut;

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _contactEmail;
  late final TextEditingController _address;
  bool _saving = false;
  bool _resetting = false;
  bool _signingOut = false;
  String? _saveError;
  String? _saveSuccess;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.phone);
    _contactEmail = TextEditingController(text: widget.contactEmail);
    _address = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _phone.dispose();
    _contactEmail.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grades =
        widget.grades
            .where((grade) => grade.studentId == widget.student.studentId)
            .toList()
          ..sort((a, b) {
            final semester = b.semester.compareTo(a.semester);
            return semester == 0
                ? a.subjectId.compareTo(b.subjectId)
                : semester;
          });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng sinh viên'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _busy ? null : _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _header(),
                const SizedBox(height: 18),
                _academicProfile(),
                const SizedBox(height: 18),
                _gradesPanel(grades),
                const SizedBox(height: 18),
                _contactPanel(),
                const SizedBox(height: 18),
                _accountPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _busy => _saving || _resetting || _signingOut;

  Widget _header() => Panel(
    color: const Color(0xFFE7F5EF),
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: Colors.white,
          child: Icon(Icons.school_rounded, color: green, size: 29),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.student.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Mã sinh viên · ${widget.student.studentId}',
                style: const TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _academicProfile() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.badge_outlined,
          title: 'Hồ sơ học vụ',
        ),
        const SizedBox(height: 8),
        const Text(
          'Thông tin do nhà trường quản lý; sinh viên chỉ có thể xem.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        _InfoRow(label: 'Mã sinh viên', value: widget.student.studentId),
        _InfoRow(label: 'Họ và tên', value: widget.student.name),
        _InfoRow(label: 'Ngành', value: widget.student.major),
        _InfoRow(label: 'Lớp', value: widget.classRoom?.name ?? 'Chưa xếp lớp'),
        _InfoRow(label: 'Mã lớp', value: widget.classRoom?.id ?? '—'),
        _InfoRow(
          label: 'Khóa',
          value: widget.classRoom?.cohort ?? '—',
          last: true,
        ),
      ],
    ),
  );

  Widget _gradesPanel(List<Grade> grades) => Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.assessment_outlined,
          title: 'Kết quả học tập',
        ),
        const SizedBox(height: 14),
        if (grades.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'Chưa có điểm được công bố.',
                style: TextStyle(color: muted),
              ),
            ),
          )
        else
          for (var i = 0; i < grades.length; i++) ...[
            _GradeRow(
              grade: grades[i],
              subject: _subjectFor(grades[i].subjectId),
            ),
            if (i < grades.length - 1) const Divider(height: 1),
          ],
      ],
    ),
  );

  Subject? _subjectFor(String id) {
    for (final subject in widget.subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  Widget _contactPanel() => Panel(
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.contact_mail_outlined,
            title: 'Thông tin liên hệ',
          ),
          const SizedBox(height: 6),
          const Text(
            'Chỉ cập nhật thông tin liên hệ; hồ sơ học vụ không bị thay đổi.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _phone,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _contactEmail,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email liên hệ',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: _validateContactEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            enabled: !_busy,
            minLines: 2,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: _validateAddress,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(
              message: _saveError!,
              color: const Color(0xFFFFECEB),
              textColor: const Color(0xFFB42318),
            ),
          ],
          if (_saveSuccess != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(
              message: _saveSuccess!,
              color: const Color(0xFFE7F5EF),
              textColor: green,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _saveContact,
              icon: _saving
                  ? const _SmallProgress()
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Đang lưu…' : 'Lưu thông tin liên hệ'),
            ),
          ),
        ],
      ),
    ),
  );

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 ||
        digits.length > 15 ||
        !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(phone)) {
      return 'Số điện thoại chưa đúng định dạng.';
    }
    return null;
  }

  String? _validateContactEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email liên hệ chưa đúng định dạng.';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final address = (value ?? '').trim();
    if (address.length > 200) return 'Địa chỉ không được vượt quá 200 ký tự.';
    return null;
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
      _saveSuccess = null;
    });
    try {
      await widget.onSaveContact(
        _phone.text.trim(),
        _contactEmail.text.trim(),
        _address.text.trim(),
      );
      if (!mounted) return;
      setState(() => _saveSuccess = 'Đã lưu thông tin liên hệ.');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _saveError = 'Không lưu được thông tin. Vui lòng thử lại.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _accountPanel() => Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.lock_outline_rounded,
          title: 'Tài khoản',
        ),
        const SizedBox(height: 12),
        const Text(
          'Email đăng nhập',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        SelectableText(
          widget.loginEmail,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Yêu cầu đặt lại mật khẩu sẽ được gửi đến email đăng nhập này, không phải email liên hệ.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.4),
        ),
        if (_actionMessage != null) ...[
          const SizedBox(height: 12),
          _MessageBanner(
            message: _actionMessage!,
            color: const Color(0xFFE7F5EF),
            textColor: green,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _requestPasswordReset,
            icon: _resetting
                ? const _SmallProgress(color: green)
                : const Icon(Icons.mark_email_read_outlined),
            label: Text(
              _resetting ? 'Đang gửi yêu cầu…' : 'Gửi email đặt lại mật khẩu',
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _signOut,
            icon: _signingOut
                ? const _SmallProgress(color: ink)
                : const Icon(Icons.logout_rounded),
            label: Text(_signingOut ? 'Đang đăng xuất…' : 'Đăng xuất'),
          ),
        ),
      ],
    ),
  );

  Future<void> _requestPasswordReset() async {
    setState(() {
      _resetting = true;
      _actionMessage = null;
    });
    try {
      await widget.onRequestPasswordReset();
      if (mounted) {
        setState(
          () => _actionMessage =
              'Đã gửi yêu cầu đặt lại mật khẩu đến ${widget.loginEmail}.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionMessage =
              'Không gửi được email đặt lại mật khẩu. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _actionMessage = null;
    });
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionMessage = 'Không đăng xuất được. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: green, size: 21),
      const SizedBox(width: 9),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFEBF0F3))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade, required this.subject});
  final Grade grade;
  final Subject? subject;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject?.name ?? grade.subjectId,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${grade.subjectId} · Học kỳ ${grade.semester}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F5EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatScore(grade.score),
            style: const TextStyle(color: green, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  String _formatScore(double score) => score == score.roundToDouble()
      ? score.toStringAsFixed(0)
      : score.toStringAsFixed(1);
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.color,
    required this.textColor,
  });
  final String message;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message, style: TextStyle(color: textColor, fontSize: 13)),
  );
}

class _SmallProgress extends StatelessWidget {
  const _SmallProgress({this.color = Colors.white});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: color),
  );
}
