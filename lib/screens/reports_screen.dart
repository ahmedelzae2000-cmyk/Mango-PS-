import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'التقرير اليومي المفصل'),
              Tab(text: 'التقرير الشهري (الورديات)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DailyReportTab(),
            _MonthlyReportTab(),
          ],
        ),
      ),
    );
  }
}

// 1. التقرير اليومي: يعرض تفاصيل الجلسات والمصاريف
class _DailyReportTab extends StatelessWidget {
  const _DailyReportTab();

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سجل الجلسات المنتهية اليوم:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('sessions').orderBy('endTime', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) return const Text('لا توجد جلسات مسجلة.');

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final endTime = (data['endTime'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.sports_esports, color: Color(0xFF1E88E5)),
                      title: Text('${data['deviceName']} (${data['deviceType']}) - ${data['mode'] == 'single' ? 'سنجل' : 'ملتي'}'),
                      subtitle: Text(DateFormat('yyyy/MM/dd - hh:mm a').format(endTime)),
                      trailing: Text('${(data['totalCost'] ?? 0).toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// 2. التقرير الشهري: ملخص الورديات
class _MonthlyReportTab extends StatelessWidget {
  const _MonthlyReportTab();

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('sessions').snapshots(),
      builder: (context, sessionSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('expenses').snapshots(),
          builder: (context, expenseSnap) {
            if (!sessionSnap.hasData || !expenseSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // تجميع البيانات حسب تاريخ الوردية
            Map<String, Map<String, double>> shiftSummary = {};

            for (var doc in sessionSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['endTime'] == null) continue;

              final date = (data['endTime'] as Timestamp).toDate();
              // تحديد تاريخ بداية الوردية (12 ظهراً)
              final shiftDate = date.hour >= 12 
                  ? DateFormat('yyyy-MM-dd').format(date)
                  : DateFormat('yyyy-MM-dd').format(date.subtract(const Duration(days: 1)));

              shiftSummary.putIfAbsent(shiftDate, () => {'cash': 0.0, 'wallets': 0.0, 'expenses': 0.0});

              final cost = (data['totalCost'] ?? 0.0).toDouble();
              if (data['paymentMethod'] == 'cash') {
                shiftSummary[shiftDate]!['cash'] = shiftSummary[shiftDate]!['cash']! + cost;
              } else {
                shiftSummary[shiftDate]!['wallets'] = shiftSummary[shiftDate]!['wallets']! + cost;
              }
            }

            for (var doc in expenseSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['dateTime'] == null) continue;

              final date = (data['dateTime'] as Timestamp).toDate();
              final shiftDate = date.hour >= 12 
                  ? DateFormat('yyyy-MM-dd').format(date)
                  : DateFormat('yyyy-MM-dd').format(date.subtract(const Duration(days: 1)));

              shiftSummary.putIfAbsent(shiftDate, () => {'cash': 0.0, 'wallets': 0.0, 'expenses': 0.0});
              shiftSummary[shiftDate]!['expenses'] = shiftSummary[shiftDate]!['expenses']! + (data['amount'] ?? 0.0).toDouble();
            }

            final sortedKeys = shiftSummary.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final summary = shiftSummary[dateKey]!;
                final totalIncome = summary['cash']! + summary['wallets']!;
                final net = totalIncome - summary['expenses']!;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ExpansionTile(
                    title: Text('وردية تاريخ: $dateKey', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الصافي: ${net.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('إجمالي الكاش:'), Text('${summary['cash']} ج.م')]),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('فودافون كاش + انستاباي:'), Text('${summary['wallets']} ج.م')]),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('المصاريف:'), Text('${summary['expenses']} ج.م', style: const TextStyle(color: Colors.redAccent))]),
                          ],
                        ),
                      )
                    ],
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
