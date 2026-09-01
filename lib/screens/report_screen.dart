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
                    trailing: Text('${cost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
                    trailing: Text('- ${amount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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

// ================= 2. التقرير الشهري المختصر (محدث ليعمل تلقائياً من الـ history) =================
class MonthlyReportView extends StatelessWidget {
  const MonthlyReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('history').snapshots(),
      builder: (context, historySnapshot) {
        if (!historySnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('expenses').snapshots(),
          builder: (context, expenseSnapshot) {
            Map<String, MonthSummary> monthlyData = {};
            double grandTotalRevenue = 0.0;
            double grandTotalCash = 0.0;
            double grandTotalVisa = 0.0;
            double grandTotalExpenses = 0.0;

            // 1. تجميع الجلسات من جدول history حسب الشهر
            for (var doc in historySnapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? time = data['timestamp'];
              if (time == null) continue;

              DateTime date = time.toDate();
              String monthKey = DateFormat('yyyy-MM').format(date);
              double cost = (data['cost'] ?? 0.0).toDouble();
              String payment = data['paymentMethod'] ?? 'كاش';

              grandTotalRevenue += cost;
              if (payment.contains('فيزا')) {
                grandTotalVisa += cost;
              } else {
                grandTotalCash += cost;
              }

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
              for (var expDoc in expenseSnapshot.data!.docs) {
                var expData = expDoc.data() as Map<String, dynamic>;
                Timestamp? time = expData['date'];
                double amount = (expData['amount'] ?? 0.0).toDouble();
                grandTotalExpenses += amount;

                if (time == null) continue;
                DateTime date = time.toDate();
                String monthKey = DateFormat('yyyy-MM').format(date);

                monthlyData.putIfAbsent(
                  monthKey, 
                  () => MonthSummary(monthName: DateFormat('MMMM yyyy', 'ar').format(date))
                );

                monthlyData[monthKey]!.totalExpenses += amount;
              }
            }

            double grandNetTotal = grandTotalRevenue - grandTotalExpenses;
            var sortedKeys = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));

            if (sortedKeys.isEmpty) {
              return const Center(child: Text('لا توجد بيانات كافية للتقارير'));
            }

            return Column(
              children: [
                // 🌟 كارت المجموع الكلي
                Card(
                  margin: const EdgeInsets.all(12),
                  color: const Color(0xFF1E1E2C),
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      children: [
                        const Text(
                          '📊 المجموع الكلي للإيرادات',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('💰 الإجمالي', grandTotalRevenue, Colors.amber),
                            _buildSummaryItem('💸 المصاريف', grandTotalExpenses, Colors.redAccent),
                            _buildSummaryItem('💎 الصافي', grandNetTotal, Colors.greenAccent),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('💵 كاش: ${grandTotalCash.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('💳 فيزا: ${grandTotalVisa.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            Text('📑 إجمالي الجلسات: ${historySnapshot.data!.docs.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // قائمة الأشهر التفصيلية
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      String key = sortedKeys[index];
                      MonthSummary summary = monthlyData[key]!;
                      double net = summary.totalRevenue - summary.totalExpenses;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('📅 ${summary.monthName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey)),
                                  Text('الصافي: ${net.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('💵 كاش: ${summary.totalCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                  Text('💳 فيزا: ${summary.totalVisa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                  Text('💸 مصاريف: ${summary.totalExpenses.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                                ],
                              ),
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
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
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
