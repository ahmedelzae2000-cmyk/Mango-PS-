Import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart'; // تأكد أن مسار الاستيراد مطابق لمشروعك

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
    // جلب صلاحية المستخدم لمعرفة هل هو مدير أم لا
    final provider = Provider.of<DeviceProvider>(context);
    final bool isManager = provider.userRole == 'مدير';

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الورديات والسجلات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // زر بدء أو إنهاء الوردية الحالية
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
                child: SizedBox(
                  width: double.infinity,
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
              );
            },
          ),

          // عرض تفاصيل الورديات مع زر الحذف للمدير فقط
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
                                    Row(
                                      children: [
                                        Text(isActive ? '🟢 نشطة' : '🔴 مغلقة', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                                        // زر حذف الوردية يظهر للمدير فقط
                                        if (isManager) ...[
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () {
                                              _showDeleteDialog(
                                                context, 
                                                'حذف هذه الوردية', 
                                                'هل أنت متأكد من حذف هذه الوردية نهائياً؟', 
                                                () async {
                                                  await db.collection('shifts').doc(shiftId).delete();
                                                }
                                              );
                                            },
                                            child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          ),
                                        ],
                                      ],
                                    ),
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

          // عرض تفاصيل الجلسات مع زر الحذف الفردي والخصم التلقائي من الوردية النشطة للمدير فقط
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
                    final historyDoc = historyDocs[index];
                    final doc = historyDoc.data() as Map<String, dynamic>;
                    String historyId = historyDoc.id;
                    String deviceName = doc['deviceName'] ?? 'جهاز';
                    double cost = (doc['cost'] ?? 0.0).toDouble();
                    String paymentMethod = doc['paymentMethod'] ?? 'كاش';
                    String closedBy = doc['closedBy'] ?? 'موظف'; // <--- قراءة اسم الشخص الذي أغلق الجلسة

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      child: ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                        title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // عرض طريقة الدفع والتكلفة ومن قام بإغلاق الجلسة
                        subtitle: Text('الدفع: $paymentMethod - التكلفة: $cost ج.م | بواسطة: $closedBy'),
                        // زر حذف الجلسة يظهر للمدير فقط في الـ Trailing مع الخصم التلقائي
                        trailing: isManager
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('حذف هذه الجلسة'),
                                      content: const Text('هل أنت متأكد من حذف هذه الجلسة من السجل وخصم قيمتها من الوردية الحالية؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          onPressed: () async {
                                            // 1. البحث عن الوردية النشطة حالياً لخصم المبلغ منها
                                            var activeShiftQuery = await db.collection('shifts').where('isActive', isEqualTo: true).get();
                                            
                                            if (activeShiftQuery.docs.isNotEmpty) {
                                              var shiftDoc = activeShiftQuery.docs.first;
                                              var shiftData = shiftDoc.data();
                                              
                                              double currentTotal = (shiftData['totalRevenue'] ?? 0.0).toDouble();
                                              double currentCash = (shiftData['cashRevenue'] ?? 0.0).toDouble();
                                              double currentVisa = (shiftData['visaRevenue'] ?? 0.0).toDouble();

                                              double newTotal = (currentTotal - cost < 0) ? 0.0 : currentTotal - cost;
                                              double newCash = currentCash;
                                              double newVisa = currentVisa;

                                              if (paymentMethod == 'كاش') {
                                                newCash = (currentCash - cost < 0) ? 0.0 : currentCash - cost;
                                              } else {
                                                newVisa = (currentVisa - cost < 0) ? 0.0 : currentVisa - cost;
                                              }

                                              // تحديث الوردية بالقيم الجديدة بعد الخصم
                                              await db.collection('shifts').doc(shiftDoc.id).update({
                                                'totalRevenue': newTotal,
                                                'cashRevenue': newCash,
                                                'visaRevenue': newVisa,
                                              });
                                            }

                                            // 2. حذف الجلسة من سجل الـ history
                                            await db.collection('history').doc(historyId).delete();
                                            
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تم حذف الجلسة وخصم قيمتها من الوردية بنجاح')),
                                            );
                                          },
                                          child: const Text('حذف وخصم'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Text('$cost ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
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

  // دالة مساعدة لعرض رسالة تأكيد الحذف العامة
  void _showDeleteDialog(BuildContext context, String title, String content, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
