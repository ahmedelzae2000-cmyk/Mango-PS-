import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: device.type == 'PS5' ? Colors.black : Colors.blue,
                      child: Text(
                        device.type,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text('${device.name} - (${device.mode == "single" ? "سنجل" : "ملتي"})'),
                    subtitle: Text('سعر الساعة: ${device.pricePerHour} ج.م'),
                    trailing: device.isOccupied
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => _showFinishDialog(context, device),
                            child: const Text('إنهاء وحساب'),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => _showStartDialog(context, device),
                            child: const Text('بدء الجلسة'),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // حوار بدء الجلسة (سنجل / ملتي)
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
                title: const Text('سنجل (Single)'),
                value: 'single',
                groupValue: selectedMode,
                onChanged: (val) => setState(() => selectedMode = val.toString()),
              ),
              RadioListTile(
                title: const Text('ملتي (Multi)'),
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
                Provider.of<DeviceProvider>(context, listen: false)
                    .startSession(device.id, selectedMode);
                Navigator.pop(ctx);
              },
              child: const Text('بدء اللعب'),
            ),
          ],
        ),
      ),
    );
  }

  // حوار إنهاء الجلسة وتعديل السعر
  void _showFinishDialog(BuildContext context, DeviceModel device) {
    final priceController = TextEditingController(text: device.pricePerHour.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنهاء جلسة: ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'تعديل سعر الساعة قبل الحساب',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              double? newPrice = double.tryParse(priceController.text);
              if (newPrice != null) {
                await Provider.of<DeviceProvider>(context, listen: false)
                    .updatePrice(device.id, newPrice);
              }
              if (context.mounted) {
                await Provider.of<DeviceProvider>(context, listen: false)
                    .stopSession(device.id);
                Navigator.pop(ctx);
              }
            },
            child: const Text('تأكيد وإنهاء الجلسة'),
          ),
        ],
      ),
    );
  }

  // حوار إضافة جهاز جديد (PS4 / PS5)
  void _showAddDeviceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '30');
    String deviceType = 'PS4';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة جهاز جديد'),
          content: Column(
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
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر الساعة الافتراضي'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  double price = double.tryParse(priceController.text) ?? 30.0;
                  Provider.of<DeviceProvider>(context, listen: false)
                      .addDevice(nameController.text, deviceType, price);
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
