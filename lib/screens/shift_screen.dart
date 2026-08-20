import 'package:flutter/material.dart';

class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الوردية الحالية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, size: 40, color: Colors.blue),
                title: const Text('الموظف المسؤول: أحمد'),
                subtitle: Text('تاريخ البدء: ${DateTime.now().toString().split(' ')[0]}'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('إجمالي الدخل:'), Text('0.00 ج.م', style: TextStyle(fontWeight: FontWeight.bold))],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('إجمالي المصاريف:'), Text('0.00 ج.م', style: TextStyle(fontWeight: FontWeight.bold))],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إغلاق الوردية بنجاح')),
                  );
                },
                child: const Text('إغلاق الوردية الحالية', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
