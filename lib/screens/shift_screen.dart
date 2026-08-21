import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  Future<void> _startShift(BuildContext context) async {
    await FirebaseFirestore.instance.collection('shifts').add({
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
      'isActive': true,
      'totalRevenue': 0.0,
      'cashRevenue': 0.0,
      'visaRevenue': 0.0,
      'expenses': 0.0, // المصاريف
    });
  }

  Future<void> _endShift(String shiftId) async {
    await FirebaseFirestore.instance.collection('shifts').doc(shiftId).update({
      'endTime': FieldValue.serverTimestamp(),
      'isActive': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الورديات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final shifts = snapshot.data!.docs;
          bool hasActiveShift = shifts.any((s) => (s.data() as Map<String, dynamic>)['isActive'] == true);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasActiveShift ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: hasActiveShift 
                      ? () => _endShift(shifts.firstWhere((s) => (s.data() as Map<String, dynamic>)['isActive'] == true).id)
                      : () => _startShift(context),
                  child: Text(
                    hasActiveShift ? 'إنهاء الوردية الحالية' : 'بدء وردية جديدة',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final data = shifts[index].data() as Map<String, dynamic>;
                    bool isActive = data['isActive'] ?? false;
                    double total = (data['totalRevenue'] ?? 0.0).toDouble();
                    double cash = (data['cashRevenue'] ?? 0.0).toDouble();
                    double visa = (data['visaRevenue'] ?? 0.0).toDouble();
                    double expenses = (data['expenses'] ?? 0.0).toDouble();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('وردية رقم ${shifts.length - index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(isActive ? '🟢 نشطة' : '🔴 مغلقة', style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                              ],
                            ),
                            const Divider(),
                            Text('💰 الإجمالي الكلي: $total ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('💵 كاش: $cash ج.م'),
                                Text('💳 فيزا: $visa ج.م'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('💸 المصاريف: $expenses ج.م', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
