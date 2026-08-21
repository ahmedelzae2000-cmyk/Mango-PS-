import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'shift_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DevicesPage(),
    const ShiftScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    
    DecorationImage? bgImage;
    if (provider.backgroundType == 'صورة مخصصة' && provider.customImagePath != null) {
      bgImage = DecorationImage(image: FileImage(File(provider.customImagePath!)), fit: BoxFit.cover);
    } else if (provider.backgroundType == 'داكن أنيق') {
      bgImage = const DecorationImage(image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover);
    }

    return Scaffold(
      body: Stack(
        children: [
          if (bgImage != null) Container(decoration: BoxDecoration(image: bgImage)),
          Container(color: provider.themeMode == ThemeMode.dark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.1)),
          SafeArea(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'الأجهزة'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الورديات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إدارة الأجهزة (Manga PS)'),
        elevation: 0,
      ),
      body: provider.devices.isEmpty
          ? const Center(child: Text('لا يوجد أجهزة، قم بإضافة جهاز جديد.'))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return DeviceCardModern(device: device);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
        title: const Text('إضافة جهاز'),
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

// --- كارت الجهاز الحديث (معالج بداخله الـ Timer والأزرار بشكل صحيح) ---
class DeviceCardModern extends StatefulWidget {
  final DeviceModel device;
  const DeviceCardModern({super.key, required this.device});

  @override
  State<DeviceCardModern> createState() => _DeviceCardModernState();
}

class _DeviceCardModernState extends State<DeviceCardModern> {
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
    double activePrice = device.mode == 'single' ? device.singlePrice : device.multiPrice;
    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      elapsed = DateTime.now().difference(device.startTime!.toDate());
      currentCost = (elapsed.inSeconds / 3600.0) * activePrice;
    }

    String formattedTime = '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: device.type == 'PS5' ? Colors.black : Colors.deepPurple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(device.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          device.isOccupied ? 'مشغول (${device.mode == "single" ? "سنجل" : "ملتي"})' : 'متاح الآن',
                          style: TextStyle(
                            color: device.isOccupied ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!device.isOccupied)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showStartDialog(context, device),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('بدء'),
                  ),
              ],
            ),
            if (device.isOccupied) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('الوقت المنقضي', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(formattedTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ],
                  ),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text('التكلفة الحالية', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${currentCost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Provider.of<DeviceProvider>(context, listen: false).toggleMode(device.id, device.mode),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(device.mode == 'single' ? 'تحويل لملتي' : 'تحويل لسنجل'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showFinishDialog(context, device, currentCost),
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('إنهاء الحساب'),
                    ),
                  ),
                ],
              ),
            ],
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
        title: const Text('بدء الجلسة'),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                double finalAmount = double.tryParse(costController.text) ?? calculatedCost;
                await Provider.of<DeviceProvider>(context, listen: false)
                    .stopSession(device.id, device.name, paymentMethod, finalAmount);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('تأكيد وحفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
