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

    DecorationImage? bgImage;
    if (provider.backgroundType == 'صورة مخصصة' && provider.customImagePath != null) {
      bgImage = DecorationImage(
        image: FileImage(File(provider.customImagePath!)),
        fit: BoxFit.cover,
      );
    } else if (provider.backgroundType == 'داكن أنيق') {
      bgImage = const DecorationImage(
        image: AssetImage('assets/bg.jpg'),
        fit: BoxFit.cover,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manga PS (${provider.userRole})'),
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.4),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              provider.setUserRole('موظف');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (bgImage != null) Container(decoration: BoxDecoration(image: bgImage)),
          Container(
            color: provider.appMode == 'داكن (Dark)'
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
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
              selectedItemColor: Colors.deepPurpleAccent,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.black.withOpacity(0.8),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Manga PS 🎮',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: provider.devices.isEmpty
          ? const Center(
              child: Text(
                'لا يوجد أجهزة مضافة حالياً',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                return DeviceGridCard(
                  key: ValueKey(provider.devices[index].id),
                  device: provider.devices[index],
                );
              },
            ),
      floatingActionButton: isManager
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showAddDeviceDialog(context),
            )
          : null,
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final sPriceController = TextEditingController(text: '30');
    final mPriceController = TextEditingController(text: '40');
    String deviceType = 'PS4';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهاز جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الجهاز'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: deviceType,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: ['PS4', 'PS5']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) deviceType = v;
                },
              ),
              TextField(
                controller: sPriceController,
                decoration: const InputDecoration(labelText: 'سعر الفردي'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: mPriceController,
                decoration: const InputDecoration(labelText: 'سعر الزوجي'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final String name = nameController.text.trim();
              if (name.isNotEmpty) {
                double s = double.tryParse(sPriceController.text) ?? 30.0;
                double m = double.tryParse(mPriceController.text) ?? 40.0;
                Provider.of<DeviceProvider>(context, listen: false)
                    .addDevice(name, deviceType, s, m);
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
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
    final bool isManager = provider.userRole == 'مدير';

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

    Color borderColor = device.isOccupied
        ? (device.isPaused ? Colors.orangeAccent : Colors.greenAccent)
        : Colors.white24;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (device.isOccupied)
                BoxShadow(
                  color: borderColor.withOpacity(0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. اسم الجهاز وأيقونة الحذف
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      device.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isManager)
                    InkWell(
                      onTap: () => _confirmDeleteDialog(context, device, provider),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                    ),
                ],
              ),

              // 2. شارة شاشة ونوع الجهاز الأيقونية
              Center(child: _buildDeviceTypeBadge(device.type)),

              // 3. العداد والمبلغ المالي
              Center(
                child: Column(
                  children: [
                    Text(
                      device.isOccupied ? formattedTime : '00:00:00',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: device.isOccupied
                            ? (device.isPaused
                                ? Colors.orangeAccent
                                : Colors.cyanAccent)
                            : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${currentCost.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. أزرار التبديل (زوجي / فردي)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _buildModeButton('زوجي', device.mode == 'multi', () {
                      provider.toggleMode(device.id, 'multi');
                    }),
                    _buildModeButton('فردي', device.mode == 'single', () {
                      provider.toggleMode(device.id, 'single');
                    }),
                  ],
                ),
              ),

              // 5. زر التشغيل أو الإيقاف / المحاسبة
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: device.isOccupied
                        ? Colors.redAccent.withOpacity(0.8)
                        : Colors.greenAccent.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () async {
                    if (!device.isOccupied) {
                      bool success =
                          await provider.startSession(device.id, device.mode);
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('لا يمكن بدء الجلسة، يجب فتح وردية أولاً!'),
                          ),
                        );
                      }
                    } else {
                      _showFinishDialog(context, device, currentCost, provider);
                    }
                  },
                  child: Text(
                    device.isOccupied ? 'إيقاف / محاسبة' : 'تشغيل',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت الشارة الأيقونية لنوع الجهاز
  Widget _buildDeviceTypeBadge(String type) {
    bool isPS5 = type.toUpperCase() == 'PS5';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isPS5
            ? Colors.blue.withOpacity(0.2)
            : Colors.indigo.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPS5 ? Colors.blueAccent : Colors.indigoAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports,
            size: 14,
            color: isPS5 ? Colors.lightBlueAccent : Colors.indigoAccent,
          ),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              color: isPS5 ? Colors.lightBlueAccent : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.extrabold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurpleAccent.withOpacity(0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDialog(
      BuildContext context, DeviceModel device, DeviceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف الجهاز ${device.name}'),
        content: const Text('هل أنت متأكد من حذف هذا الجهاز نهائياً؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deleteDevice(device.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, DeviceModel device,
      double calculatedCost, DeviceProvider provider) {
    final costController =
        TextEditingController(text: calculatedCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'إدارة جلسة: ${device.name}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: costController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ النهائي (تعديل السعر ج.م)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurple)),
                ),
              ),
              const SizedBox(height: 15),
              const Text('طريقة الدفع',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepPurple)),
                ),
                items: ['كاش', 'فيزا']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => paymentMethod = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    device.isPaused ? Colors.greenAccent : Colors.orangeAccent,
              ),
              onPressed: () async {
                await provider.togglePauseSession(device.id, device.isPaused);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(device.isPaused ? 'استئناف العداد' : 'إيقاف مؤقت'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                double parsedVal =
                    double.tryParse(costController.text) ?? calculatedCost;
                await provider.stopSession(
                  device.id,
                  device.name,
                  paymentMethod,
                  parsedVal >= 0 ? parsedVal : calculatedCost,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ وتسجيل الفاتورة'),
            ),
          ],
        ),
      ),
    );
  }
}
 
