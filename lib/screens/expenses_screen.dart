import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المصاريف')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('expenses').orderBy('dateTime', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['dateTime'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('yyyy/MM/dd - hh:mm a').format(date)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${data['amount']} ج.م', style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => firestore.collection('expenses').doc(doc.id).delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مصروف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'بيان المصروف')),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ (ج.م)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('expenses').add({
                  'title': titleCtrl.text,
                  'amount': double.parse(amountCtrl.text),
                  'dateTime': Timestamp.now(),
                  'addedBy': 'موظف',
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('تسجيل وخصم'),
          )
        ],
      ),
    );
  }
}
