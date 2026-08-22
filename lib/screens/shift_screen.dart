import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expenses_screen.dart'; // تأكد من استيراد شاشة المصاريف

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
          // زر المصاريف في الـ AppBar
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
          // زر بدء أو إنهاء الوردية + زر التقرير
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final shifts = snapshot.data!.docs;
              var activeShiftDoc = shifts.where((s) => (s.data() as Map<String, dynamic>)['isActive'] == true);
              bool hasActiveShift = activeShiftDoc.isNotEmpty;
              String? activeShiftId = hasActiveShift ? activeShiftDoc.first.id : null;

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
                    // زر التقرير المالي للوردية النشطة
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 45),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showReportDialog(context, activeShiftId),
                        icon: const Icon(Icons.assessment, size: 18),
                        label: const Text('تقرير'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // عرض تفاصيل الورديات
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final shifts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final data = shifts[index].data() as Map<String, dynamic>;
                    bool isActive = data['isActive'] ?? false;
                    double total = (data['totalRevenue'] ?? 0.0).toDouble();
                    double cash = (data['cashRevenue'] ?? 0.0).toDouble();
                    double visa = (data['visaRevenue'] ?? 0.0).toDouble();
                    double expenses = (data['expenses'] ?? 0.0).toDouble();

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
                            Text('💰 الإجمالي الكلي: $total ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 13)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('💵 كاش: $cash ج.م', style: const TextStyle(fontSize: 12)),
                                Text('💳 فيزا: $visa ج.م', style: const TextStyle(fontSize: 12)),
                                Text('💸 مصاريف: $expenses ج.م', style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  // دالة جلب وعرض تقرير الوردية النشطة من Firebase مباشرة
  void _showReportDialog(BuildContext context, String? shiftId) async {
    if (shiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد وردية نشطة حالياً لعرض تقريرها')),
      );
      return;
    }

    // جلب بيانات الوردية الحالية
    var shiftDoc = await FirebaseFirestore.instance.collection('shifts').doc(shiftId).get();
    if (!shiftDoc.exists) return;
    var shiftData = shiftDoc.data() as Map<String, dynamic>;
    double totalRevenue = (shiftData['totalRevenue'] ?? 0.0).toDouble();
    double cashRevenue = (shiftData['cashRevenue'] ?? 0.0).toDouble();
    double visaRevenue = (shiftData['visaRevenue'] ?? 0.0).toDouble();

    // جلب المصاريف والسلف المرتبطة بهذه الوردية من كولكشن expenses
    var expensesQuery = await FirebaseFirestore.instance
        .collection('expenses')
        .where('shiftId', isEqualTo: shiftId)
        .get();

    double totalExpenses = 0.0;
    double totalAdvances = 0.0;

    for (var doc in expensesQuery.docs) {
      var data = doc.data();
      double amount = (data['amount'] ?? 0.0).toDouble();
      String type = data['type'] ?? 'مصروف';
      if (type == 'مصروف') {
        totalExpenses += amount;
      } else if (type == 'سلفة') {
        totalAdvances += amount;
      }
    }

    double netProfit = totalRevenue - totalExpenses;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('التقرير المالي للوردية النشطة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('إجمالي المبيعات'),
              trailing: Text('$totalRevenue ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('إجمالي الكاش / الفيزا'),
              trailing: Text('كاش: $cashRevenue | فيزا: $visaRevenue', style: const TextStyle(fontSize: 12)),
            ),
            const Divider(),
            ListTile(
              title: const Text('إجمالي المصاريف'),
              trailing: Text('$totalExpenses ج.م', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('إجمالي السلف'),
              trailing: Text('$totalAdvances ج.م', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              title: const Text('صافي الخزنة (بعد المصاريف)', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('$netProfit ج.م', style: TextStyle(fontWeight: FontWeight.bold, color: netProfit >= 0 ? Colors.deepPurple : Colors.red)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
