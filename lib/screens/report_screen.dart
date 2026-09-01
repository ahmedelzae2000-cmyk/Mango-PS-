import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

// ================= 1. التقرير اليومي المفصل =================
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
                    trailing: Text('${cost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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

// ================= 2. التقرير الشهري المختصر (معتمد على جدول الأرشيف والمصاريف) =================
class MonthlyReportView extends StatelessWidget {
  const MonthlyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('history').snapshots(), // الاعتماد على جدول الجلسات المكتملة
      builder: (context, historySnapshot) {
        if (!historySnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final historyDocs = historySnapshot.data!.docs;

        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('expenses').snapshots(),
          builder: (context, expenseSnapshot) {
            Map<String, MonthSummary> monthlyData = {};

            // 1. تجميع إيرادات الجلسات حسب الشهر
            for (var doc in historyDocs) {
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? time = data['timestamp'];
              if (time == null) continue;

              DateTime date = time.toDate();
              String monthKey = DateFormat('yyyy-MM').format(date);
              double cost = (data['cost'] ?? 0.0).toDouble();
              String payment = data['paymentMethod'] ?? 'كاش';

              monthlyData.putIfAbsent(
                monthKey, 
                () => MonthSummary(monthName: DateFormat('MMMM yyyy', 'ar').format(date))
              );

              monthlyData[monthKey]!.totalRevenue += cost;
              if (payment.contains('فيزا')) {
                monthlyData[monthKey]!.totalVisa += cost;
              } else {
                monthlyData[monthKey]!.totalCash += cost;
              }
              monthlyData[monthKey]!.shiftCount += 1;
            }

            // 2. تجميع المصاريف حسب الشهر
            if (expenseSnapshot.hasData) {
              for (var doc in expenseSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                Timestamp? time = data['date'];
                if (time == null) continue;

                DateTime date = time.toDate();
                String monthKey = DateFormat('yyyy-MM').format(date);
                double amount = (data['amount'] ?? 0.0).toDouble();

                monthlyData.putIfAbsent(
                  monthKey, 
                  () => MonthSummary(monthName: DateFormat('MMMM yyyy', 'ar').format(date))
                );

                monthlyData[monthKey]!.totalExpenses += amount;
              }
            }

            var sortedKeys = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));

            if (sortedKeys.isEmpty) {
              return const Center(child: Text('لا توجد بيانات كافية للتقارير الشهرية'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                String key = sortedKeys[index];
                MonthSummary summary = monthlyData[key]!;
                double netTotal = summary.totalRevenue - summary.totalExpenses;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color(0xFF1E1E2C),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📅 ${summary.monthName}',
                              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'عدد الجلسات: ${summary.shiftCount}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('💰 الإجمالي', summary.totalRevenue, Colors.amberAccent),
                            _buildSummaryItem('💸 المصاريف', summary.totalExpenses, Colors.redAccent),
                            _buildSummaryItem('💎 الصافي', netTotal, Colors.greenAccent),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('💵 كاش: ${summary.totalCash.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('💳 فيزا: ${summary.totalVisa.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  Widget _buildSummaryItem(String title, double amount, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} ج.م',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class MonthSummary {
  String monthName;
  double totalRevenue;
  double totalCash;
  double totalVisa;
  double totalExpenses;
  int shiftCount;

  MonthSummary({
    required this.monthName,
    this.totalRevenue = 0.0,
    this.totalCash = 0.0,
    this.totalVisa = 0.0,
    this.totalExpenses = 0.0,
    this.shiftCount = 0,
  });
}
