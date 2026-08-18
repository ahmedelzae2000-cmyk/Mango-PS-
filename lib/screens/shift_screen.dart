import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  // تحديد بداية ونهاية الوردية الحالية (12:00 ظهراً - 12:00 ظهر الغد)
  DateTime get _shiftStart {
    final now = DateTime.now();
    if (now.hour >= 12) {
      return DateTime(now.year, now.month, now.day, 12, 0);
    } else {
      return DateTime(now.year, now.month, now.day - 1, 12, 0);
    }
  }

  DateTime get _shiftEnd => _shiftStart.add(const Duration(hours: 24));

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الوردية الحالية (12 ظ - 12 ظ)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('sessions')
            .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(_shiftStart))
            .where('endTime', isLessThan: Timestamp.fromDate(_shiftEnd))
            .snapshots(),
        builder: (context, sessionSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('expenses')
                .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(_shiftStart))
                .where('dateTime', isLessThan: Timestamp.fromDate(_shiftEnd))
                .snapshots(),
            builder: (context, expenseSnap) {
              if (!sessionSnap.hasData || !expenseSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              double totalCash = 0.0;
              double totalWallets = 0.0; // فودافون كاش + انستاباي

              for (var doc in sessionSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final cost = (data['totalCost'] ?? 0.0).toDouble();
                final method = data['paymentMethod'] ?? 'cash';

                if (method == 'cash') {
                  totalCash += cost;
                } else {
                  totalWallets += cost;
                }
              }

              double totalExpenses = 0.0;
              final expenseDocs = expenseSnap.data!.docs;
              for (var doc in expenseDocs) {
                final data = doc.data() as Map<String, dynamic>;
                totalExpenses += (data['amount'] ?? 0.0).toDouble();
              }

              final grossIncome = totalCash + totalWallets;
              final netIncome = grossIncome - totalExpenses;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // كارت إجمالي الدخل الصافي
                    Card(
                      color: const Color(0xFF1E88E5),
                      child: ListTile(
                        title: const Text('صافي الدخل (بعد خصم المصاريف)', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${netIncome.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // تفاصيل الإيرادات والمصاريف
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'إجمالي الكاش',
                            amount: totalCash,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            title: 'فودافون + انستاباي',
                            amount: totalWallets,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Card(
                      color: const Color(0xFF2C1E1E),
                      child: ListTile(
                        title: const Text('إجمالي المصاريف'),
                        subtitle: Text('${totalExpenses.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 18, color: Colors.redAccent)),
                        trailing: ElevatedButton(
                          onPressed: () => _showExpensesDetails(context, expenseDocs),
                          child: const Text('التفاصيل'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showExpensesDetails(BuildContext context, List<QueryDocumentSnapshot> docs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (_) => ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, i) {
          final data = docs[i].data() as Map<String, dynamic>;
          final timeStr = DateFormat('hh:mm a - yyyy/MM/dd').format((data['dateTime'] as Timestamp).toDate());
          return ListTile(
            title: Text(data['title'] ?? ''),
            subtitle: Text(timeStr),
            trailing: Text('${data['amount']} ج.م', style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _StatCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text('${amount.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
