import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // بدء وردية جديدة
  Future<void> _startShift() async {
    await _db.collection('shifts').add({
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
      'isActive': true,
      'cashInDrawer': 0, // الرصيد المبدئي
    });
  }

  // إنهاء الوردية
  Future<void> _endShift(String shiftId) async {
    await _db.collection('shifts').doc(shiftId).update({
      'endTime': FieldValue.serverTimestamp(),
      'isActive': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الورديات'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('shifts').orderBy('startTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final shifts = snapshot.data!.docs;
          bool hasActiveShift = shifts.any((s) => s['isActive'] == true);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasActiveShift ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: hasActiveShift 
                      ? () => _endShift(shifts.firstWhere((s) => s['isActive'] == true).id)
                      : _startShift,
                  child: Text(hasActiveShift ? 'إنهاء الوردية الحالية' : 'بدء وردية جديدة', style: const TextStyle(color: Colors.white)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final data = shifts[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('وردية رقم ${index + 1}'),
                      subtitle: Text(data['isActive'] ? 'نشطة حالياً' : 'مغلقة'),
                      trailing: Text(data['isActive'] ? '🟢' : '🔴'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
