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
      appBar: AppBar(title: const Text('إدارة الأجهزة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إضافة جهاز جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الجهاز (مثل: جهاز 1)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'PS5', child: Text('PlayStation 5')),
                DropdownMenuItem(value: 'PS4', child: Text('PlayStation 4')),
                DropdownMenuItem(value: 'VR', child: Text('VR')),
              ],
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: const InputDecoration(
                labelText: 'نوع الجهاز',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('حفظ الجهاز'),
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty) {
                    deviceProvider.addDevice(_nameController.text.trim(), _selectedType);
                    _nameController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة الجهاز بنجاح!')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('الأجهزة المضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: deviceProvider.devices.length,
                itemBuilder: (context, index) {
                  final dev = deviceProvider.devices[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.tv),
                      title: Text(dev.name),
                      subtitle: Text('النوع: ${dev.type}'),
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
