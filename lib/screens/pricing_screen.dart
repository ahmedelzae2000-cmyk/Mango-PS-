import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _nameController = TextEditingController();
  String _selectedType = 'PS5';

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأجهزة والأسعار'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إضافة جهاز جديد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الجهاز (مثال: جهاز 3)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'PS5', child: Text('PlayStation 5')),
                DropdownMenuItem(value: 'PS4', child: Text('PlayStation 4')),
                DropdownMenuItem(value: 'VR', child: Text('VR Headset')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
              decoration: const InputDecoration(
                labelText: 'نوع الجهاز',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('حفظ وإضافة الجهاز'),
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty) {
                    deviceProvider.addDevice(
                      _nameController.text.trim(),
                      _selectedType,
                    );
                    _nameController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة الجهاز بنجاح!')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الأجهزة الحالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: deviceProvider.devices.length,
                itemBuilder: (context, index) {
                  final device = deviceProvider.devices[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.sports_esports),
                      title: Text(device.name),
                      subtitle: Text('النوع: ${device.type}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
