import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'shift_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'expenses_screen.dart'; 
import 'report_screen.dart'; // تم تعديل اسم الملف هنا بدون حرف s

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

    List<Widget> pages = [
      const DevicesPage(),
      const ShiftScreen(),
      if (isManager) ...[
        const ExpensesScreen(),
        const ReportScreen(), // التأكد من مطابقة اسم الكونستركتور أيضاً
        const SettingsScreen(),
      ],
    ];

    if (!isManager && _selectedIndex > 1) {
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex >= pages.length ? 0 : _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'الأجهزة'),
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الورديات'),
          if (isManager) ...[
            const BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'المصاريف'),
            const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ],
      ),
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
                crossAxisCount: 2, // جهازين في كل صف بالشكل الشبابي
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.4, // كارت عريض وأنيق
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
    final bool isDark = provider.appMode == 'داكن (Dark)';
    
    double activePrice = device.mode == 'single' ? device.singlePrice : device.multiPrice;
    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      elapsed = DateTime.now().difference(device.startTime!.toDate());
      currentCost = (elapsed.inSeconds / 3600.0) * activePrice;
    }

    String formattedTime = '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (!device.isOccupied) {
          _showStartDialog(context, device);
        } else {
          _showFinishDialog(context, device, currentCost);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900.withOpacity(0.85) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: device.isOccupied ? Colors.redAccent.withOpacity(0.8) : Colors.greenAccent.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: device.isOccupied ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: device.type == 'PS5' ? Colors.black : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    device.type,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      ),
                      Text(
                        '${currentCost.toStringAsFixed(1)} ج.م',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                    ],
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
    String mode = 'single';
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
 
