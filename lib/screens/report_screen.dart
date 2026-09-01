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

// ================= 2. التقرير الشهري المختصر (مع خانة تجميع الورديات) =================
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

        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('expenses').snapshots(),
          builder: (context, expenseSnapshot) {
            double grandTotalRevenue = 0.0;
            double grandTotalCash = 0.0;
            double grandTotalVisa = 0.0;
            double grandTotalExpenses = 0.0;

            // 1. حساب إجمالي جميع الورديات
            for (var shiftDoc in shifts) {
              var data = shiftDoc.data() as Map<String, dynamic>;
              grandTotalRevenue += (data['totalRevenue'] ?? 0.0).toDouble();
              grandTotalCash += (data['cashRevenue'] ?? 0.0).toDouble();
              grandTotalVisa += (data['visaRevenue'] ?? 0.0).toDouble();
            }

            // 2. حساب إجمالي كافة المصاريف
            if (expenseSnapshot.hasData) {
              for (var expDoc in expenseSnapshot.data!.docs) {
                grandTotalExpenses += ((expDoc.data() as Map<String, dynamic>)['amount'] ?? 0.0).toDouble();
              }
            }

            double grandNetTotal = grandTotalRevenue - grandTotalExpenses;

            return Column(
              children: [
                // 🌟 كارت المجموع الكلي (إحصائيات الورديات بالكامل)
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
                          '📊 المجموع الكلي لجميع الورديات',
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
                            Text('💵 كاش: ${grandTotalCash.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('💳 فيزا: ${grandTotalVisa.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('📑 عدد الورديات: ${shifts.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // قائمة الورديات التفصيلية
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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

                      double shiftExpenses = 0.0;
                      if (expenseSnapshot.hasData) {
                        for (var exp in expenseSnapshot.data!.docs) {
                          var expData = exp.data() as Map<String, dynamic>;
                          if (expData['shiftId'] == shiftId) {
                            shiftExpenses += (expData['amount'] ?? 0.0).toDouble();
                          }
                        }
                      }

                      double net = total - shiftExpenses;

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
                                  Text('📅 $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                                  Text('الصافي: ${net.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal)),
                                ],
                              ),
                              const Divider(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('💵 كاش: ${cash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                  Text('💳 فيزا: ${visa.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                  Text('💸 مصاريف: ${shiftExpenses.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
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

  // عنصر تجميلي لعرض الإحصائيات داخل الخانة العلوية
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
