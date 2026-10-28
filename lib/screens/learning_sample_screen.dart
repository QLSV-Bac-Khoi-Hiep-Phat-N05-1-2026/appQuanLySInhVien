import 'package:flutter/material.dart';

/// Reproduction of the supplied learning-app layout using original Flutter art.
class LearningSampleScreen extends StatelessWidget {
  const LearningSampleScreen({super.key});

  void _info(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Đây là màn hình mẫu bố cục học tập cho Câu 5. Chức năng quản lý của dự án nằm trong trang chính.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE9EEF6),
    appBar: AppBar(
      title: const Text('Màn hình mẫu · Câu 5'),
      backgroundColor: Colors.white,
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF2F5FD),
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Row(
                      children: [
                        const Text('🦉', style: TextStyle(fontSize: 36)),
                        const SizedBox(width: 9),
                        const Text(
                          'Lớp 12 ⌄',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Text(
                            '⭐ 0',
                            style: TextStyle(
                              color: Color(0xFFE2BC00),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _info(context, 'Thông báo'),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _tile(
                            context,
                            'Gia sư\nDicabee',
                            Icons.smart_toy_rounded,
                            const Color(0xFF2EDB48),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: _tile(
                                  context,
                                  'Chụp ảnh\nBài tập',
                                  Icons.camera_alt_rounded,
                                  const Color(0xFFFFBD0B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _tile(
                                  context,
                                  'Nhập\nCâu hỏi',
                                  Icons.keyboard_rounded,
                                  const Color(0xFF33C4F5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _utility(
                          context,
                          'Từ điển',
                          Icons.translate,
                          Colors.lightBlue,
                        ),
                        _utility(
                          context,
                          'Cân bằng\nPTHH',
                          Icons.science_outlined,
                          Colors.deepOrangeAccent,
                        ),
                        _utility(
                          context,
                          'Máy tính\nthông minh',
                          Icons.calculate_outlined,
                          Colors.amber,
                        ),
                        _utility(
                          context,
                          'Đếm\nngược',
                          Icons.timer_outlined,
                          Colors.green,
                        ),
                        _utility(
                          context,
                          'Bảng\nTHHH',
                          Icons.grid_on_rounded,
                          Colors.purpleAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      height: 250,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB7F0F6), Color(0xFFFFF3BC)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -28,
                            right: -35,
                            child: _bubble(
                              150,
                              Colors.white.withValues(alpha: .6),
                            ),
                          ),
                          Positioned(
                            bottom: -25,
                            left: -20,
                            child: _bubble(
                              120,
                              Colors.white.withValues(alpha: .6),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 110,
                            child: Transform.rotate(
                              angle: -.3,
                              child: const Icon(
                                Icons.headphones_rounded,
                                size: 62,
                                color: Color(0xFFB29B7D),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 120,
                            child: Transform.rotate(
                              angle: .25,
                              child: const Icon(
                                Icons.calculate_rounded,
                                size: 64,
                                color: Color(0xFF91A9BA),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'HỘP QUÀ',
                                  style: TextStyle(
                                    fontSize: 27,
                                    color: Color(0xFF69AF2B),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const Text(
                                  'MAY MẮN',
                                  style: TextStyle(
                                    fontSize: 35,
                                    color: Color(0xFFF3AA15),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Icon(
                                  Icons.redeem_rounded,
                                  size: 94,
                                  color: Color(0xFFF7B916),
                                ),
                                Container(
                                  height: 10,
                                  width: 165,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: .25),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Góc giải trí',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _game(
                                context,
                                'Thông Điệp',
                                Icons.auto_awesome,
                                const Color(0xFF453271),
                              ),
                              _game(
                                context,
                                'Ca Rô đại',
                                Icons.close_rounded,
                                const Color(0xFF526577),
                              ),
                              _game(
                                context,
                                'Đuổi hình',
                                Icons.extension,
                                const Color(0xFF42D9CE),
                              ),
                              _game(
                                context,
                                'Giải cứu',
                                Icons.smart_toy,
                                const Color(0xFF6FA5D4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _nav('Trang chủ', Icons.home_filled, true),
                  _nav('Luyện đề', Icons.military_tech_outlined, false),
                  _nav('Khóa học', Icons.ondemand_video_outlined, false),
                  _nav('Hỏi đáp', Icons.forum_outlined, false),
                  _nav('Học Tập', Icons.menu_book_outlined, false),
                  _nav('Cá nhân', Icons.person_outline, false),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tile(BuildContext context, String name, IconData icon, Color color) =>
      Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _info(context, name.replaceAll('\n', ' ')),
          child: Container(
            height: 139,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  Widget _utility(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) => Expanded(
    child: InkWell(
      onTap: () => _info(context, label.replaceAll('\n', ' ')),
      child: SizedBox(
        child: Column(
          children: [
            Badge(
              label: const Text('Hot', style: TextStyle(fontSize: 8)),
              backgroundColor: const Color(0xFFFF7D65),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64737F)),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _game(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) => Expanded(
    child: InkWell(
      onTap: () => _info(context, label),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF7B8794)),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _nav(String name, IconData icon, bool active) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 23,
          color: active ? Colors.lightBlue : const Color(0xFF89949B),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 9,
              color: active ? Colors.lightBlue : const Color(0xFF89949B),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _bubble(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
