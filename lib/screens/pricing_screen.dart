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
  final _singleRateController = TextEditingController(text: '20');
  final _multiRateController = TextEditingController(text: '30');
  String _selectedType = 'PS4';

  @override
  Widget build(BuildContext context) {
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأجهزة والأسعار'),
      ),
      body: SingleChildScrollView(
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
                labelText: 'اسم الجهاز (مثال: جهاز 1)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع الجهاز',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PS4', child: Text('PS4')),
                DropdownMenuItem(value: 'PS5', child: Text('PS5')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _singleRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر الساعة سنجل (ج.م)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _multiRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر الساعة ملتي (ج.م)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) return;

                  final single = double.tryParse(_singleRateController.text) ?? 20.0;
                  final multi = double.tryParse(_multiRateController.text) ?? 30.0;

                  deviceProvider.addDevice(
                    _nameController.text.trim(),
                    _selectedType,
                    singleRate: single,
                    multiRate: multi,
                  );

                  _nameController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة الجهاز بنجاح')),
                  );
                },
                child: const Text('حفظ الجهاز'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
