import 'dart:async';
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
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, provider),
          const SizedBox(height: 12),
          provider.devices.isEmpty
              ? Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: const Text(
                    'لا يوجد أجهزة مضافة حالياً',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.78, // زيادة تم تعديلها لتصغير ارتفاع المربع
                  ),
                  itemCount: provider.devices.length,
                  itemBuilder: (context, index) {
                    return DeviceGridCard(
                      key: ValueKey(provider.devices[index].id),
                      device: provider.devices[index],
                    );
                  },
                ),
          const SizedBox(height: 16),
          _buildShiftSummary(),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DeviceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF151F32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports, color: Color(0xFF00D2FF), size: 26),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'إدارة محل البلايستيشن',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(
                    'Play • Game • Enjoy',
                    style: TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, color: Colors.white70, size: 10),
                    SizedBox(width: 3),
                    Text('الشيفت الحالي',
                        style: TextStyle(color: Colors.white70, fontSize: 9)),
                  ],
                ),
                Text(
                  '06:00 ص - 06:00 م',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  '● مستمر',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bar_chart, color: Color(0xFF00D2FF), size: 16),
            SizedBox(width: 6),
            Text(
              'ملخص الشيفت الحالي',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF151F32),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 8)),
            const SizedBox(height: 2),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(color: Colors.white38, fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3.2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                device.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  device.type,
                  style: const TextStyle(
                      color: Color(0xFF00D2FF),
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1527),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPriceHeader('سنجل', device.singlePrice),
                const SizedBox(
                    height: 12, child: VerticalDivider(color: Colors.white12)),
                _buildPriceHeader('مالتي', device.multiPrice),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                device.isOccupied ? formattedTime : '00:00:00',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: device.isOccupied
                      ? (device.isPaused ? Colors.orangeAccent : Colors.greenAccent)
                      : Colors.white38,
                ),
              ),
              Text(
                '${currentCost.toStringAsFixed(2)} جنيه',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
            ],
          ),
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(5),
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
          SizedBox(
            width: double.infinity,
            height: 26,
            child: device.isOccupied
                ? Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          device.isPaused ? Icons.play_arrow : Icons.pause,
                          color: device.isPaused ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        onPressed: () {
                          provider.togglePauseSession(device.id, device.isPaused);
                        },
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {},
                          child: const Text('إنهاء الجلسة',
                              style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () async {
                      await provider.startSession(device.id, device.mode);
                    },
                    child: const Text('إبدأ جلسة',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHeader(String title, double price) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 8)),
        Text('${price.toInt()} ج',
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
