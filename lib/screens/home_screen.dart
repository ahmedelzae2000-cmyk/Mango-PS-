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
                double activePrice = device.mode == 'single' ? device.singlePrice : device.multiPrice;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: device.type == 'PS5' ? Colors.black : Colors.blue,
                            child: Text(device.type, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('السعر الحالي: $activePrice ج.م / ساعة (${device.mode == "single" ? "سنجل" : "ملتي"})'),
                          trailing: device.isOccupied
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // زر التبديل السريع بين سنجل وملتي والجلسة شغالة
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                                      tooltip: 'تغيير الوضع (سنجل/ملتي)',
                                      onPressed: () {
                                        provider.toggleMode(device.id, device.mode);
                                      },
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      onPressed: () => _showFinishDialog(context, device),
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
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // نافذة بدء الجلسة واختيار الوضع
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

  // نافذة إنهاء الجلسة واختيار طريقة الدفع (كاش / فيزا)
  void _showFinishDialog(BuildContext context, DeviceModel device) {
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('إنهاء وحساب: ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر طريقة الدفع:'),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await Provider.of<DeviceProvider>(context, listen: false).stopSession(device.id, paymentMethod);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إنهاء الجلسة بنجاح والدفع بنظام: $paymentMethod')),
                  );
                }
              },
              child: const Text('تأكيد الحساب'),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة إضافة جهاز جديد مع أسعار سنجل وملتي
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
