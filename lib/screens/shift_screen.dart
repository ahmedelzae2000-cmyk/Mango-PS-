import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_drawer.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  DateTime _getShiftStartTime() {
    final now = DateTime.now();
    if (now.hour >= 12) {
      return DateTime(now.year, now.month, now.day, 12, 0, 0);
    } else {
      return DateTime(now.year, now.month, now.day - 1, 12, 0, 0);
    }
  }

  DateTime _getShiftEndTime() {
    return _getShiftStartTime().add(const Duration(hours: 24));
  }

  void _showStartShiftDialog(String userName) {
    final drawerController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('فتح وردية جديدة (12 ظهراً)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text('اسم الموظف: $userName'),
              const SizedBox(height: 10),
              TextField(
                controller: drawerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عهدة بداية الوردية / الدرج (ج.م)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final double startAmount = double.tryParse(drawerController.text) ?? 0.0;
                await FirebaseFirestore.instance.collection('shifts').add({
                  'employeeName': userName,
                  'startTime': FieldValue.serverTimestamp(),
                  'scheduledShiftStart': Timestamp.fromDate(_getShiftStartTime()),
                  'scheduledShiftEnd': Timestamp.fromDate(_getShiftEndTime()),
                  'initialDrawer': startAmount,
                  'status': 'open',
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('فتح الوردية', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEndShiftDialog(
    DocumentSnapshot shiftDoc,
    double cashIncome,
    double visaIncome,
    double expenses,
    double initialDrawer,
  ) {
    final totalIncome = cashIncome + visaIncome;
    final drawerCashNet = initialDrawer + cashIncome - expenses; // المطلوب بالدرج نقدياً
    final netProfit = totalIncome - expenses; // الإيراد الإجمالي المتبقي بعد المصاريف

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تقرير إغلاق الوردية'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text('عهدة بداية الوردية: ${initialDrawer.toStringAsFixed(2)} ج.م'),
                const Divider(),
                Text('💵 إجمالي الكاش: ${cashIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('💳 إجمالي الفيزا: ${visaIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                Text('📊 إجمالي المبيعات (كاش+فيزا): ${totalIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                Text('🔻 إجمالي المصاريف: ${expenses.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.amber.withOpacity(0.2),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text('💵 الصافي المطلوبة بالدرج (كاش): ${drawerCashNet.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('📈 الصافي الإيراد الكلي بعد المصاريف: ${netProfit.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('shifts').doc(shiftDoc.id).update({
                  'status': 'closed',
                  'endTime': FieldValue.serverTimestamp(),
                  'totalCash': cashIncome,
                  'totalVisa': visaIncome,
                  'totalIncome': totalIncome,
                  'totalExpenses': expenses,
                  'finalDrawerCash': drawerCashNet,
                  'netProfit': netProfit,
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('تأكيد إغلاق الوردية', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDarkMode = appProvider.isDarkMode;
    final shiftStart = _getShiftStartTime();
    final shiftEnd = _getShiftEndTime();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('إدارة الوردية والحسابات'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('shifts')
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final openShifts = snapshot.data?.docs ?? [];
          final bool isShiftOpen = openShifts.isNotEmpty;
          final DocumentSnapshot? currentShift = isShiftOpen ? openShifts.first : null;
          final Map<String, dynamic>? shiftData = currentShift?.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // كارت تفاصيل الوردية المفتوحة
                Card(
                  color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isShiftOpen ? 'الوردية الحالية (12ظ - 12ظ)' : 'لا توجد وردية مفتوحة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isShiftOpen ? Colors.green : Colors.orange,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isShiftOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isShiftOpen ? 'مفتوحة' : 'مغلقة',
                                style: TextStyle(color: isShiftOpen ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text('فترة الوردية: ${DateFormat('MM-dd hh:mm a').format(shiftStart)} ⬅️ ${DateFormat('MM-dd hh:mm a').format(shiftEnd)}'),
                        if (isShiftOpen) ...[
                          Text('الموظف: ${shiftData?['employeeName'] ?? ''}'),
                          Text('العهدة المبدئية بالدرج: ${(shiftData?['initialDrawer'] ?? 0.0).toStringAsFixed(2)} ج.م'),
                        ],
                        const SizedBox(height: 15),

                        // حساب مبيعات الكاش والفيزا والمصاريف الحالية
                        if (isShiftOpen)
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('sessions')
                                .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(shiftStart))
                                .snapshots(),
                            builder: (context, sessionSnap) {
                              double cashIncome = 0.0;
                              double visaIncome = 0.0;

                              if (sessionSnap.hasData) {
                                for (var doc in sessionSnap.data!.docs) {
                                  final cost = (doc['cost'] ?? 0.0).toDouble();
                                  final method = doc['paymentMethod'] ?? 'كاش';
                                  if (method == 'فيزا') {
                                    visaIncome += cost;
                                  } else {
                                    cashIncome += cost;
                                  }
                                }
                              }

                              return StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('expenses')
                                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(shiftStart))
                                    .snapshots(),
                                builder: (context, expSnap) {
                                  double expenses = 0.0;
                                  if (expSnap.hasData) {
                                    for (var doc in expSnap.data!.docs) {
                                      expenses += (doc['amount'] ?? 0.0).toDouble();
                                    }
                                  }

                                  final initialDrawer = (shiftData?['initialDrawer'] ?? 0.0).toDouble();
                                  final drawerCashNet = initialDrawer + cashIncome - expenses;
                                  final totalIncome = cashIncome + visaIncome;
                                  final netProfit = totalIncome - expenses;

                                  return Column(
                                    children: [
                                      // ملخص الأرقام الحية للوردية
                                      Row(
                                        children: [
                                          Expanded(child: _buildStatCard('💵 الكاش', '${cashIncome.toStringAsFixed(2)} ج.م', Colors.green)),
                                          Expanded(child: _buildStatCard('💳 الفيزا', '${visaIncome.toStringAsFixed(2)} ج.م', Colors.blue)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(child: _buildStatCard('🔻 المصاريف', '${expenses.toStringAsFixed(2)} ج.م', Colors.red)),
                                          Expanded(child: _buildStatCard('📥 بالدرج (كاش)', '${drawerCashNet.toStringAsFixed(2)} ج.م', Colors.amber)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          icon: const Icon(Icons.stop_circle, color: Colors.white),
                                          label: const Text('إنهاء الوردية وجرد الحساب', style: TextStyle(color: Colors.white, fontSize: 16)),
                                          onPressed: () => _showEndShiftDialog(
                                            currentShift!,
                                            cashIncome,
                                            visaIncome,
                                            expenses,
                                            initialDrawer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                              label: const Text('فتح وردية جديدة', style: TextStyle(color: Colors.white, fontSize: 16)),
                              onPressed: () => _showStartShiftDialog(appProvider.userName.isEmpty ? 'الموظف' : appProvider.userName),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // جدول الجلسات بالتفصيل
                const Text('كشف جلسات اللعب بالوردية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(shiftStart))
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Card(child: Padding(padding: EdgeInsets.all(12.0), child: Text('لا توجد جلسات في هذه الوردية')));
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final Timestamp? time = data['timestamp'] as Timestamp?;
                        final String timeStr = time != null ? DateFormat('hh:mm a').format(time.toDate()) : '';
                        final String method = data['paymentMethod'] ?? 'كاش';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              method == 'فيزا' ? Icons.credit_card : Icons.money,
                              color: method == 'فيزا' ? Colors.blue : Colors.green,
                            ),
                            title: Text('جهاز: ${data['deviceName'] ?? ''} (${data['sessionType'] ?? ''})'),
                            subtitle: Text('الوقت: $timeStr | المدة: ${data['duration'] ?? ''} | طريقه الدفع: $method'),
                            trailing: Text(
                              '${(data['cost'] ?? 0.0).toStringAsFixed(2)} ج.م',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
