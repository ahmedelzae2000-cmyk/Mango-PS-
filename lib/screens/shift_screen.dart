import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expenses_screen.dart'; // شاشة المصاريف المنفصلة
import 'report_screen.dart';   // شاشة التقرير المالي المنفصلة

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
      'expenses': 0.0,
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
        title: const Text('إدارة الورديات والسجلات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // زر المصاريف في الـ AppBar لينتقل للشاشة المنفصلة
          IconButton(
            icon: const Icon(Icons.money_off),
            tooltip: 'المصاريف والسلف',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // زر بدء أو إنهاء الوردية + زر التقرير المنفصل
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final shifts = snapshot.data!.docs;
              bool hasActiveShift = shifts.any((s) => (s.data() as Map<String, dynamic>)['isActive'] == true);
              
              String? activeShiftId;
              if (hasActiveShift) {
                activeShiftId = shifts.firstWhere((s) => (s.data() as Map<String, dynamic>)['isActive'] == true).id;
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasActiveShift ? Colors.red : Colors.green,
                          minimumSize: const Size(double.infinity, 45),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: hasActiveShift 
                            ? () => _endShift(activeShiftId!)
                            : () => _startShift(context),
                        child: Text(
                          hasActiveShift ? 'إنهاء الوردية الحالية' : 'بدء وردية جديدة',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // زر الانتقال لشاشة التقرير المالي المنفصلة
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 45),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportScreen()),
                          );
                        },
                        icon: const Icon(Icons.assessment, size: 18),
                        label: const Text('تقرير'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // عرض تفاصيل الورديات مع حساب المصاريف والسلف تلقائياً
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
              builder: (context, shiftSnapshot) {
                if (!shiftSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                final shifts = shiftSnapshot.data!.docs;

                if (shifts.isEmpty) {
                  return const Center(child: Text('لا توجد ورديات مسجلة'));
                }

                return ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final shiftDoc = shifts[index];
                    final shiftData = shiftDoc.data() as Map<String, dynamic>;
                    String shiftId = shiftDoc.id;
                    bool isActive = shiftData['isActive'] ?? false;
                    double total = (shiftData['totalRevenue'] ?? 0.0).toDouble();
                    double cash = (shiftData['cashRevenue'] ?? 0.0).toDouble();
                    double visa = (shiftData['visaRevenue'] ?? 0.0).toDouble();

                    // استخدام Stream فرعي لحساب المصاريف الخاصة بهذه الوردية لحظياً
                    return StreamBuilder<QuerySnapshot>(
                      stream: db.collection('expenses').where('shiftId', isEqualTo: shiftId).snapshots(),
                      builder: (context, expenseSnapshot) {
                        double shiftExpenses = 0.0;
                        if (expenseSnapshot.hasData) {
                          for (var expDoc in expenseSnapshot.data!.docs) {
                            var expData = expDoc.data() as Map<String, dynamic>;
                            shiftExpenses += (expData['amount'] ?? 0.0).toDouble();
                          }
                        }

                        // حساب الصافي (المبيعات - المصاريف)
                        double netTotal = total - shiftExpenses;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('وردية رقم ${shifts.length - index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(isActive ? '🟢 نشطة' : '🔴 مغلقة', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                                  ],
                                ),
                                const Divider(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('💰 الإجمالي: $total ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 13)),
                                    Text('💎 الصافي: $netTotal ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('💵 كاش: $cash ج.م', style: const TextStyle(fontSize: 12)),
                                    Text('💳 فيزا: $visa ج.م', style: const TextStyle(fontSize: 12)),
                                    Text('💸 مصاريف: $shiftExpenses ج.م', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('سجل الجلسات المنتهية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple)),
            ),
          ),

          // عرض تفاصيل كل جلسة انتهت
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('history').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final historyDocs = snapshot.data!.docs;

                if (historyDocs.isEmpty) {
                  return const Center(child: Text('لا توجد جلسات منتهية حتى الآن', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: historyDocs.length,
                  itemBuilder: (context, index) {
                    final doc = historyDocs[index].data() as Map<String, dynamic>;
                    String deviceName = doc['deviceName'] ?? 'جهاز';
                    double cost = (doc['cost'] ?? 0.0).toDouble();
                    String paymentMethod = doc['paymentMethod'] ?? 'كاش';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                        title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('طريقة الدفع: $paymentMethod'),
                        trailing: Text('$cost ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 
