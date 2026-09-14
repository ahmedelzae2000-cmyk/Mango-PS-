import 'dart0:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'expenses_screen.dart';
import 'login_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'shift_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final bool isManager = provider.userRole == 'مدير';

    final List<Widget> pages = [
      const DevicesPage(),
      if (isManager) ...[
        const ShiftScreen(),
        const ExpensesScreen(),
        const ReportScreen(),
        const SettingsScreen(),
      ],
    ];

    if (!isManager && _selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // لون خلفية فرعي داكن وجذاب
      body: Stack(
        children: [
          // خلفية التدرج المتوهج
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x3300D2FF),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x229D4EDD),
              ),
            ),
          ),
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isManager
          ? BottomNavigationBar(
              currentIndex: _selectedIndex >= pages.length ? 0 : _selectedIndex,
              selectedItemColor: const Color(0xFF00D2FF),
              unselectedItemColor: Colors.white38,
              backgroundColor: const Color(0xFF0D1527),
              type: BottomNavigationBarType.fixed,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'الأجهزة'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الورديات'),
                BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'المصاريف'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
              ],
            )
          : null,
    );
  }
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    final bool isManager = provider.userRole == 'مدير';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. الهيدر العلوي (معلومات الشيفت)
          _buildHeader(context, provider),

          const SizedBox(height: 16),

          // 2. شبكة الأجهزة المضافة
          provider.devices.isEmpty
              ? const Container(
                  height: 200,
                  child: Center(
                    child: Text(
                      'لا يوجد أجهزة مضافة حالياً',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.58, // نسبة متناسقة لعرض البيانات كاملة
                  ),
                  itemCount: provider.devices.length,
                  itemBuilder: (context, index) {
                    return DeviceGridCard(
                      key: ValueKey(provider.devices[index].id),
                      device: provider.devices[index],
                    );
                  },
                ),

          const SizedBox(height: 20),

          // 3. قسم ملخص الشيفت الحالي
          _buildShiftSummary(),

          const SizedBox(height: 16),

          // 4. أزرار الإجراءات السريعة (إنهاء، إضافة مصروف...)
          _buildQuickActions(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ودجت الهيدر
  Widget _buildHeader(BuildContext context, DeviceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151F32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports, color: Color(0xFF00D2FF), size: 30),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'إدارة محل البلايستيشن',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Text(
                    'Play • Game • Enjoy',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, color: Colors.white70, size: 12),
                    SizedBox(width: 4),
                    Text('الشيفت الحالي',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                Text(
                  '06:00 ص - 06:00 م',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  '● مستمر',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ودجت ملخص الشيفت
  Widget _buildShiftSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bar_chart, color: Color(0xFF00D2FF), size: 18),
            SizedBox(width: 6),
            Text(
              'ملخص الشيفت الحالي',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatItem('عدد الجلسات', '14', 'جلسة', Icons.sports_esports, Colors.purpleAccent),
            _buildStatItem('إجمالي الإيرادات', '1,400', 'جنيه', Icons.account_balance_wallet, Colors.blueAccent),
            _buildStatItem('صافي الشيفت', '1,250', 'جنيه', Icons.attach_money, Colors.greenAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, String unit, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF151F32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9)),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(color: Colors.white38, fontSize: 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // أزرار التحكم السريع
  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildActionButton('إنهاء الشيفت', Icons.power_settings_new, const Color(0xFF5C1D24)),
        _buildActionButton('إضافة مصروف', Icons.receipt_long, const Color(0xFF5C3B12)),
        _buildActionButton('إضافة إيراد يدوي', Icons.add_circle_outline, const Color(0xFF134E35)),
        _buildActionButton('سجل الأيام السابقة', Icons.history, const Color(0xFF3B1D5C)),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color bg) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class DeviceGridCard extends StatefulWidget {
  final DeviceModel device;
  const DeviceGridCard({super.key, required this.device});

  @override
  State<DeviceGridCard> createState() => _DeviceGridCardState();
}

class _DeviceGridCardState extends State<DeviceGridCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DeviceGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.device.isOccupied != oldWidget.device.isOccupied ||
        widget.device.isPaused != oldWidget.device.isPaused) {
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.device.isOccupied && !widget.device.isPaused) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final provider = Provider.of<DeviceProvider>(context, listen: false);

    final double activePrice =
        device.mode == 'single' ? device.singlePrice : device.multiPrice;

    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      final DateTime now = DateTime.now();
      final DateTime start = device.startTime!.toDate();

      int totalPausedSeconds = device.pausedDuration;
      if (device.isPaused && device.pauseStartTime != null) {
        totalPausedSeconds +=
            now.difference(device.pauseStartTime!.toDate()).inSeconds;
      }

      int elapsedSeconds = now.difference(start).inSeconds - totalPausedSeconds;
      if (elapsedSeconds < 0) elapsedSeconds = 0;

      elapsed = Duration(seconds: elapsedSeconds);
      currentCost = (elapsedSeconds / 3600.0) * activePrice;
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String formattedTime =
        '${twoDigits(elapsed.inHours)}:${twoDigits(elapsed.inMinutes % 60)}:${twoDigits(elapsed.inSeconds % 60)}';

    Color cardBorder = device.isOccupied
        ? (device.isPaused ? Colors.orangeAccent : const Color(0xFF00D2FF))
        : Colors.white10;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151F32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          if (device.isOccupied)
            BoxShadow(
              color: cardBorder.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1,
            )
        ],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. رأس الكارت (الاسم والنوع)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                device.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  device.type,
                  style: const TextStyle(
                      color: Color(0xFF00D2FF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // 2. الأسعار (سنجل / مالتي)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPriceHeader('سنجل', device.singlePrice),
                const SizedBox(
                    height: 15, child: VerticalDivider(color: Colors.white12)),
                _buildPriceHeader('مالتي', device.multiPrice),
              ],
            ),
          ),

          // 3. الوقت والمبلغ
          Column(
            children: [
              Text(
                device.isOccupied ? formattedTime : '00:00:00',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: device.isOccupied
                      ? (device.isPaused ? Colors.orangeAccent : Colors.greenAccent)
                      : Colors.white38,
                ),
              ),
              Text(
                '${currentCost.toStringAsFixed(2)} جنيه',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
            ],
          ),

          // 4. أزرار التبديل (سنجل / مالتي)
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _buildModeButton('سنجل', device.mode == 'single', () {
                  provider.toggleMode(device.id, 'single');
                }),
                _buildModeButton('مالتي', device.mode == 'multi', () {
                  provider.toggleMode(device.id, 'multi');
                }),
              ],
            ),
          ),

          // 5. زر التحكم الرئيسي (إبدأ / إنهاء)
          SizedBox(
            width: double.infinity,
            height: 30,
            child: device.isOccupied
                ? Row(
                    children: [
                      // زر إيقاف مؤقت
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          device.isPaused ? Icons.play_arrow : Icons.pause,
                          color: device.isPaused ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        onPressed: () {
                          provider.togglePauseSession(device.id, device.isPaused);
                        },
                      ),
                      const SizedBox(width: 4),
                      // زر إنهاء الجلسة
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {},
                          child: const Text('إنهاء الجلسة',
                              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () async {
                      await provider.startSession(device.id, device.mode);
                    },
                    child: const Text('إبدأ جلسة',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHeader(String title, double price) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        Text('${price.toInt()} ج',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModeButton(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
      
