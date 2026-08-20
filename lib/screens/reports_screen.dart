import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والإحصائيات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: const ListTile(
                leading: Icon(Icons.analytics, color: Colors.blue, size: 36),
                title: Text('ملخص اليوم'),
                subtitle: Text('إجمالي ساعات اللعب: 0 ساعة'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              child: const ListTile(
                leading: Icon(Icons.attach_money, color: Colors.green, size: 36),
                title: Text('إجمالي الإيرادات'),
                subtitle: Text('0.00 ج.م'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
