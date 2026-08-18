import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../models/device_model.dart';
import 'login_screen.dart';
import 'shift_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'pricing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS - الشاشة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1F1F1F)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_esports, size: 50, color: Color(0xFF1E88E5)),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.isAdmin ? 'حساب: صاحب المحل' : 'حساب: موظف',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('الوردية الحالية'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('المصاريف'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('التقارير'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
            ),
            if (authProvider.isAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('تعديل الأسعار وإضافة أجهزة'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen())),
              ),
            ],
          ],
        ),
      ),
      body: deviceProvider.devices.isEmpty
          ? const Center(child: Text('لا يوجد أجهزة مضافة حتى الآن'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: deviceProvider.devices.length,
              itemBuilder: (context, index) {
                final device = deviceProvider.devices[index];
                return _DeviceCard(device: device);
              },
            ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context, listen: false);
    final cost = provider.calculateCurrentCost(device);

    return Card(
      color: device.isOccupied ? const Color(0xFF2C1E1E) : const Color(0xFF1E2C1E),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: device.isOccupied ? Colors.redAccent : Colors.greenAccent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(
                  label: Text(device.type, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.black25,
                ),
              ],
            ),
            if (device.isOccupied) ...[
              Text(
                '${cost.toStringAsFixed(2)} ج.م',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              Text('النمط: ${device.mode == GameMode.single ? "سنجل" : "ملتي"}'),
              Text('الدفع: ${_paymentText(device.paymentMethod)}'),
            ] else
              const Text('الجهاز متاح', style: TextStyle(color: Colors.grey)),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: device.isOccupied ? Colors.red : Colors.green,
                ),
                onPressed: () {
                  if (device.isOccupied) {
                    _showEndSessionDialog(context, device);
                  } else {
                    _showStartSessionDialog(context, device);
                  }
                },
                child: Text(device.isOccupied ? 'إنهاء / تعديل' : 'بدء الجلسة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paymentText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'كاش';
      case PaymentMethod.vodafoneCash: return 'فودافون كاش';
      case PaymentMethod.instapay: return 'انستاباي';
    }
  }

  void _showStartSessionDialog(BuildContext context, DeviceModel device) {
    GameMode selectedMode = GameMode.single;
    PaymentMethod selectedPayment = PaymentMethod.cash;

    showDialog(
      context: context,
      builder: (ctx) => StatefulWidgetBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('بدء جلسة - ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<GameMode>(
                value: selectedMode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: GameMode.single, child: Text('سنجل')),
                  DropdownMenuItem(value: GameMode.multi, child: Text('ملتي')),
                ],
                onChanged: (val) => setState(() => selectedMode = val!),
              ),
              DropdownButton<PaymentMethod>(
                value: selectedPayment,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش')),
                  DropdownMenuItem(value: PaymentMethod.vodafoneCash, child: Text('فودافون كاش')),
                  DropdownMenuItem(value: PaymentMethod.instapay, child: Text('انستاباي')),
                ],
                onChanged: (val) => setState(() => selectedPayment = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<DeviceProvider>(context, listen: false)
                    .startSession(device.id, selectedMode, selectedPayment);
                Navigator.pop(ctx);
              },
              child: const Text('تشغيل'),
            )
          ],
        ),
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context, DeviceModel device) {
    final provider = Provider.of<DeviceProvider>(context, listen: false);
    final amountController = TextEditingController(text: provider.calculateCurrentCost(device).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنهاء الجلسة - ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'تعديل الحساب النهائي (ج.م)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newAmount = double.tryParse(amountController.text) ?? 0;
              provider.updateCustomAmount(device.id, newAmount).then((_) {
                provider.endSession(device);
                Navigator.pop(ctx);
              });
            },
            child: const Text('تأكيد وإغلاق الجلسة', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
