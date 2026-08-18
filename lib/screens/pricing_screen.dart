import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../models/pricing_model.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  late TextEditingController ps4SingleCtrl;
  late TextEditingController ps4MultiCtrl;
  late TextEditingController ps5SingleCtrl;
  late TextEditingController ps5MultiCtrl;

  @override
  void initState() {
    super.initState();
    final pricing = Provider.of<DeviceProvider>(context, listen: false).pricing;
    ps4SingleCtrl = TextEditingController(text: pricing.ps4SingleRate.toString());
    ps4MultiCtrl = TextEditingController(text: pricing.ps4MultiRate.toString());
    ps5SingleCtrl = TextEditingController(text: pricing.ps5SingleRate.toString());
    ps5MultiCtrl = TextEditingController(text: pricing.ps5MultiRate.toString());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الأسعار والأجهزة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              icon: const Icon(Icons.add_to_queue),
              label: const Text('إضافة جهاز جديد يدويًا'),
              onPressed: () => _showAddDeviceDialog(context),
            ),
            const SizedBox(height: 24),
            const Text('أسعار PS4 (ساعة):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: ps4SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سنجل (ج.م)')),
            TextField(controller: ps4MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ملتي (ج.م)')),
            const SizedBox(height: 20),
            const Text('أسعار PS5 (ساعة):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: ps5SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سنجل (ج.م)')),
            TextField(controller: ps5MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ملتي (ج.م)')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  final newPricing = PricingModel(
                    ps4SingleRate: double.tryParse(ps4SingleCtrl.text) ?? 30.0,
                    ps4MultiRate: double.tryParse(ps4MultiCtrl.text) ?? 40.0,
                    ps5SingleRate: double.tryParse(ps5SingleCtrl.text) ?? 50.0,
                    ps5MultiRate: double.tryParse(ps5MultiCtrl.text) ?? 70.0,
                  );
                  provider.updatePricing(newPricing);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الأسعار الجديدة')));
                },
                child: const Text('حفظ التعديلات', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedType = 'PS4';

    showDialog(
      context: context,
      builder: (ctx) => StatefulWidgetBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة جهاز جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الجهاز (مثل: جهاز 1)')),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'PS4', child: Text('PS4')),
                  DropdownMenuItem(value: 'PS5', child: Text('PS5')),
                ],
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  Provider.of<DeviceProvider>(context, listen: false).addDevice(nameCtrl.text, selectedType);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة'),
            )
          ],
        ),
      ),
    );
  }
}
