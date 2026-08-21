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
                  decoration: const InputDecoration(labelText: 'اسم الجهاز'),
                ),
                DropdownButton<String>(
                  value: deviceType,
                  isExpanded: true,
                  items: ['PS4', 'PS5'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => deviceType = val!),
                ),
                TextField(controller: singlePriceController, decoration: const InputDecoration(labelText: 'سعر الساعة سنجل'), keyboardType: TextInputType.number),
                TextField(controller: multiPriceController, decoration: const InputDecoration(labelText: 'سعر الساعة ملتي'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                double sPrice = double.tryParse(singlePriceController.text) ?? 30.0;
                double mPrice = double.tryParse(multiPriceController.text) ?? 40.0;
                Provider.of<DeviceProvider>(context, listen: false).addDevice(nameController.text, deviceType, sPrice, mPrice);
                Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }
}

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
      if (widget.device.isOccupied) setState(() {});
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
    Duration elapsed = device.isOccupied && device.startTime != null 
        ? DateTime.now().difference(device.startTime!.toDate()) 
        : Duration.zero;
    double currentCost = (elapsed.inSeconds / 3600.0) * activePrice;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(device.type)),
        title: Text(device.name),
        subtitle: device.isOccupied
            ? Text('الوقت: ${elapsed.inMinutes} دقيقة | الحساب: ${currentCost.toStringAsFixed(2)} ج.م')
            : const Text('متاح'),
        trailing: device.isOccupied
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.swap_horiz), onPressed: () => Provider.of<DeviceProvider>(context, listen: false).toggleMode(device.id, device.mode)),
                  ElevatedButton(onPressed: () => _showFinishDialog(context, device, currentCost), child: const Text('إنهاء')),
                ],
              )
            : ElevatedButton(onPressed: () => _showStartDialog(context, device), child: const Text('بدء')),
      ),
    );
  }

  void _showFinishDialog(BuildContext context, DeviceModel device, double calculatedCost) {
    final costController = TextEditingController(text: calculatedCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنهاء حساب ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ الإجمالي')),
            DropdownButton<String>(
              value: paymentMethod,
              items: ['كاش', 'فيزا'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => paymentMethod = val!),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              double finalAmount = double.tryParse(costController.text) ?? calculatedCost;
              // التعديل هنا: تمرير 4 معاملات (id, name, paymentMethod, amount)
              await Provider.of<DeviceProvider>(context, listen: false)
                  .stopSession(device.id, device.name, paymentMethod, finalAmount);
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
  
  void _showStartDialog(BuildContext context, DeviceModel device) {
    String mode = 'single';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('بدء الجلسة'),
      content: StatefulBuilder(builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile(title: const Text('سنجل'), value: 'single', groupValue: mode, onChanged: (v) => setState(() => mode = v!)),
          RadioListTile(title: const Text('ملتي'), value: 'multi', groupValue: mode, onChanged: (v) => setState(() => mode = v!)),
        ],
      )),
      actions: [
        ElevatedButton(onPressed: () {
          Provider.of<DeviceProvider>(context, listen: false).startSession(device.id, mode);
          Navigator.pop(ctx);
        }, child: const Text('بدء')),
      ],
    ));
  }
}
