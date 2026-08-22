import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'shift_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'expenses_screen.dart'; 
import 'report_screen.dart';

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

    // الصفحات التي تظهر بناءً على الصلاحية
    List<Widget> pages = [
      const DevicesPage(),
      if (isManager) ...[
        const ShiftScreen(),
        const ExpensesScreen(),
        const ReportScreen(),
        const SettingsScreen(),
      ],
    ];

    // لو الموظف غير المؤشر وتم إخفاء الصفحات، نعيده للصفحة الأولى
    if (!isManager && _selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    DecorationImage? bgImage;
    if (provider.backgroundType == 'صورة مخصصة' && provider.customImagePath != null) {
      bgImage = DecorationImage(image: FileImage(File(provider.customImagePath!)), fit: BoxFit.cover);
    } else if (provider.backgroundType == 'داكن أنيق') {
      bgImage = const DecorationImage(image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manga PS (${provider.userRole})'),
        elevation: 0,
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
          Container(color: provider.appMode == 'داكن (Dark)' ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.1)),
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      // إظهار شريط التنقل السفلي للمدير فقط، أو إخفاؤه تماماً لو الموظف لا يملك سوى شاشة واحدة
      bottomNavigationBar: isManager
          ? BottomNavigationBar(
              currentIndex: _selectedIndex >= pages.length ? 0 : _selectedIndex,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
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
          : null, // الموظف لن يظهر له شريط سفلي طالما يملك شاشة الأجهزة فقط
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
          'صالة الأجهزة',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.35,
              ),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return DeviceGridCard(device: device);
              },
            ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة جهاز', style: TextStyle(color: Colors.white)),
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
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الجهاز')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: deviceType,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: ['PS4', 'PS5'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => deviceType = v!,
              ),
              TextField(controller: sPriceController, decoration: const InputDecoration(labelText: 'سعر السنجل'), keyboardType: TextInputType.number),
              TextField(controller: mPriceController, decoration: const InputDecoration(labelText: 'سعر الملتي'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              double s = double.tryParse(sPriceController.text) ?? 30.0;
              double m = double.tryParse(mPriceController.text) ?? 40.0;
              Provider.of<DeviceProvider>(context, listen: false)
                  .addDevice(nameController.text, deviceType, s, m);
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.device.isOccupied) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final provider = Provider.of<DeviceProvider>(context);
    final bool isManager = provider.userRole == 'مدير';
    final bool isDark = provider.appMode == 'داكن (Dark)';
    
    double activePrice = device.mode == 'single' ? device.singlePrice : device.multiPrice;
    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      elapsed = DateTime.now().difference(device.startTime!.toDate());
      currentCost = (elapsed.inSeconds / 3600.0) * activePrice;
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String formattedTime = '${twoDigits(elapsed.inHours)}:${twoDigits(elapsed.inMinutes % 60)}:${twoDigits(elapsed.inSeconds % 60)}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // الضغط العادي: لبدء أو إنهاء الجلسة
      onTap: () async {
        if (!device.isOccupied) {
          bool success = await provider.startSession(device.id, device.mode);
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لا يمكن بدء الجلسة، يجب فتح وردية أولاً!')),
            );
            return;
          }
          if (success && context.mounted) {
            _showStartDialog(context, device);
          }
        } else {
          _showFinishDialog(context, device, currentCost);
        }
      },
      // الضغط المطول: لحذف الجهاز (للمدير فقط)
      onLongPress: () {
        if (isManager) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('حذف الجهاز ${device.name}'),
              content: const Text('هل أنت متأكد من حذف هذا الجهاز نهائياً؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    provider.deleteDevice(device.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم حذف ${device.name} بنجاح')),
                    );
                  },
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900.withOpacity(0.9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: device.isOccupied ? Colors.redAccent.withOpacity(0.9) : Colors.greenAccent.withOpacity(0.9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: device.isOccupied ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: device.type == 'PS5' ? Colors.blueGrey.shade900 : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sports_esports, color: Colors.amberAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        device.type,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOccupied ? Colors.redAccent : Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.isOccupied ? (device.mode == 'single' ? 'سنجل' : 'ملتي') : 'متاح',
                      style: TextStyle(
                        color: device.isOccupied ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Center(
              child: Text(
                device.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            device.isOccupied
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.amberAccent,
                          ),
                        ),
                        Text(
                          '${currentCost.toStringAsFixed(1)} ج.م',
                          style: const TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text(
                      'انقر لبدء الجلسة',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context, DeviceModel device) {
    String mode = device.mode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('بدء جلسة ${device.name}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(title: const Text('سنجل'), value: 'single', groupValue: mode, onChanged: (v) => setState(() => mode = v!)),
              RadioListTile(title: const Text('ملتي'), value: 'multi', groupValue: mode, onChanged: (v) => setState(() => mode = v!)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Provider.of<DeviceProvider>(context, listen: false).startSession(device.id, mode);
              Navigator.pop(ctx);
            },
            child: const Text('بدء'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, DeviceModel device, double calculatedCost) {
    final costController = TextEditingController(text: calculatedCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('إنهاء حساب ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ الإجمالي (ج.م)'),
              ),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: paymentMethod,
                isExpanded: true,
                items: ['كاش', 'فيزا'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => paymentMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<DeviceProvider>(context, listen: false).toggleMode(device.id, device.mode);
                Navigator.pop(ctx);
              },
              child: Text(device.mode == 'single' ? 'تحويل لملتي' : 'تحويل لسنجل'),
            ),
            ElevatedButton(
              onPressed: () async {
                double parsedVal = double.tryParse(costController.text) ?? calculatedCost;
                double finalAmount = parsedVal >= 0 ? parsedVal : calculatedCost;
                await Provider.of<DeviceProvider>(context, listen: false)
                    .stopSession(device.id, device.name, paymentMethod, finalAmount);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('إنهاء ودفع'),
            ),
          ],
        ),
      ),
    );
  }
}
 
 
