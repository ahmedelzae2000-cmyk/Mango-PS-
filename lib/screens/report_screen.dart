import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لتنسيق التواريخ بشكل جميل

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير المالية والتشغيلية'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'التقرير اليومي المفصل'),
              Tab(icon: Icon(Icons.calendar_month), text: 'التقرير الشهري المختصر'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DailyReportView(),
            MonthlyReportView(),
          ],
        ),
      ),
    );
  }
}

// ================= 1. التقرير اليومي (الجلسات والمصاريف بالتاريخ) =================
class DailyReportView extends StatelessWidget {
  const DailyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'سجل جلسات اليوم والمصاريف',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 10),

        // عرض الجلسات المنتهية مع تواريخها
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('history').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد جلسات مسجلة')));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                String device = data['deviceName'] ?? 'جهاز';
                double cost = (data['cost'] ?? 0.0).toDouble();
                String payment = data['paymentMethod'] ?? 'كاش';
                Timestamp? time = data['timestamp'];
                String formattedDate = time != null 
                    ? DateFormat('yyyy-MM-dd – hh:mm a').format(time.toDate()) 
                    : 'جاري الحفظ...';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.games, color: Colors.teal),
                    title: Text(device, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$formattedDate | الدفع: $payment'),
                    trailing: Text('$cost ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 20),
        const Text(
          'المصاريف والسلف المسجلة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        const SizedBox(height: 10),

        // عرض المصاريف اليومية
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('expenses').orderBy('date', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لا توجد مصاريف مسجلة')));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                String title = data['title'] ?? '';
                double amount = (data['amount'] ?? 0.0).toDouble();
                String type = data['type'] ?? 'مصروف';
                Timestamp? time = data['date'];
                String formattedDate = time != null 
                    ? DateFormat('yyyy-MM-dd – hh:mm a').format(time.toDate()) 
                    : '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(type == 'مصروف' ? Icons.money_off : Icons.person_pin, color: Colors.red),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$type | $formattedDate'),
                    trailing: Text('- $amount ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ================= 2. التقرير الشهري المختصر (الورديات بالتاريخ) =================
class MonthlyReportView extends StatelessWidget {
  const MonthlyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
      builder: (context, shiftSnapshot) {
        if (!shiftSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final shifts = shiftSnapshot.data!.docs;

        if (shifts.isEmpty) {
          return const Center(child: Text('لا توجد ورديات مسجلة'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: shifts.length,
          itemBuilder: (context, index) {
            var shiftDoc = shifts[index];
            var data = shiftDoc.data() as Map<String, dynamic>;
            String shiftId = shiftDoc.id;

            double total = (data['totalRevenue'] ?? 0.0).toDouble();
            double cash = (data['cashRevenue'] ?? 0.0).toDouble();
            double visa = (data['visaRevenue'] ?? 0.0).toDouble();
            Timestamp? startTime = data['startTime'];
            String dateStr = startTime != null 
                ? DateFormat('yyyy-MM-dd (hh:mm a)').format(startTime.toDate()) 
                : 'وردية حالية';

            // حساب المصاريف الخاصة بالوردية دي
            return StreamBuilder<QuerySnapshot>(
              stream: db.collection('expenses').where('shiftId', isEqualTo: shiftId).snapshots(),
              builder: (context, expenseSnapshot) {
                double expenses = 0.0;
                if (expenseSnapshot.hasData) {
                  for (var exp in expenseSnapshot.data!.docs) {
                    expenses += ((exp.data() as Map<String, dynamic>)['amount'] ?? 0.0).toDouble();
                  }
                }

                double net = total - expenses;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('📅 $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                            Text('الصافي: ${net.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('💵 كاش: $cash', style: const TextStyle(fontSize: 12)),
                            Text('💳 فيزا: $visa', style: const TextStyle(fontSize: 12)),
                            Text('💸 مصاريف: $expenses', style: const TextStyle(fontSize: 12, color: Colors.red)),
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
    );
  }
}
