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

  @override
  Widget build(BuildContext context) {
    // قائمة الشاشات (الأجهزة مع كل مميزاتها، الورديات، الإعدادات)
    final List<Widget> pages = [
      const DevicesPage(),
      const ShiftScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
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

// صفحة الأجهزة بكل التعديلات والعدادات السابقة
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأجهزة (Mango PS)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: provider.devices.isEmpty
          ? const Center(child: Text('لا يوجد أجهزة، قم بإضافة جهاز جديد.'))
          : ListView.builder(
              itemCount: provider.devices.length,
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return DeviceCard(device: device);
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
    final singlePriceController = TextEditingController(text: '30');
    final multiPriceController = TextEditingController(text: '40');
    String deviceType = 'PS4';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة جهاز جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الجهاز (مثلاً: جهاز 1)'),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: deviceType,
                  isExpanded: true,
                  items: ['PS4', 'PS5'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => deviceType = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: singlePriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الساعة سنجل'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: multiPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الساعة ملتي'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  double sPrice = double.tryParse(singlePriceController.text) ?? 30.0;
                  double mPrice = double.tryParse(multiPriceController.text) ?? 40.0;
                  Provider.of<DeviceProvider>(context, listen: false)
                      .addDevice(nameController.text, deviceType, sPrice, mPrice);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

// كارت الجهاز الذي يحتوي على العداد الحي والتبديل وزر الحساب
class DeviceCard extends StatefulWidget {
  final DeviceModel device;
  const DeviceCard({super.key, required this.device});

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.device.isOccupied) {
        setState(() {});
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
    double activePricePerHour = device.mode == 'single' ? device.singlePrice : device.multiPrice;

    Duration elapsed = Duration.zero;
    double currentCost = 0.0;

    if (device.isOccupied && device.startTime != null) {
      elapsed = DateTime.now().difference(device.startTime!.toDate());
      double hours = elapsed.inSeconds / 3600.0;
      currentCost = hours * activePricePerHour;
    }

    String formattedTime = 
        '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: device.type == 'PS5' ? Colors.black : Colors.blue,
                child: Text(device.type, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: device.isOccupied
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text('الوضع: ${device.mode == "single" ? "سنجل" : "ملتي"} ($activePricePerHour ج/س)'),
                        const SizedBox(height: 3),
                        Text('الوقت: $formattedTime', style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        Text('التكلفة: ${currentCost.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text('الجهاز متاح الآن', style: TextStyle(color: Colors.grey)),
              trailing: device.isOccupied
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                          tooltip: 'تبديل سنجل/ملتي',
                          onPressed: () {
                            Provider.of<DeviceProvider>(context, listen: false).toggleMode(device.id, device.mode);
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () => _showFinishDialog(context, device, currentCost),
                          child: const Text('إنهاء وحساب'),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _showStartDialog(context, device),
                      child: const Text('بدء الجلسة'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context, DeviceModel device) {
    String selectedMode = 'single';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('بدء جلسة: ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: Text('سنجل (${device.singlePrice} ج.م)'),
                value: 'single',
                groupValue: selectedMode,
                onChanged: (val) => setState(() => selectedMode = val.toString()),
              ),
              RadioListTile(
                title: Text('ملتي (${device.multiPrice} ج.م)'),
                value: 'multi',
                groupValue: selectedMode,
                onChanged: (val) => setState(() => selectedMode = val.toString()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Provider.of<DeviceProvider>(context, listen: false).startSession(device.id, selectedMode);
                Navigator.pop(ctx);
              },
              child: const Text('بدء اللعب'),
            ),
          ],
        ),
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
          title: Text('حساب وإنهاء: ${device.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'تعديل المبلغ الإجمالي قبل الحساب (ج.م)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('طريقة الدفع:'),
                RadioListTile(
                  title: const Text('كاش (Cash)'),
                  value: 'كاش',
                  groupValue: paymentMethod,
                  onChanged: (val) => setState(() => paymentMethod = val.toString()),
                ),
                RadioListTile(
                  title: const Text('فيزا (Visa)'),
                  value: 'فيزا',
                  groupValue: paymentMethod,
                  onChanged: (val) => setState(() => paymentMethod = val.toString()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                double finalAmount = double.tryParse(costController.text) ?? calculatedCost;
                await Provider.of<DeviceProvider>(context, listen: false)
                    .stopSession(device.id, paymentMethod, finalAmount);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إغلاق الحساب بنجاح. المبلغ: $finalAmount ج.م ($paymentMethod)')),
                  );
                }
              },
              child: const Text('تأكيد وإغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
 
