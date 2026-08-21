import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('تعديل الأسعار والأجهزة'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('devices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد أجهزة مضافة'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'جهاز',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سعر السنجل: ${data['singlePrice'] ?? 0} ج.م / ساعة'),
                      Text('سعر المالتي: ${data['multiPrice'] ?? 0} ج.م / ساعة'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditDialog(doc.id, data);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final singleController = TextEditingController(text: data['singlePrice']?.toString());
    final multiController = TextEditingController(text: data['multiPrice']?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل أسعار ${data['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: singleController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر الساعة (Single)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: multiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر الساعة (Multi)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('devices').doc(docId).update({
                'singlePrice': double.tryParse(singleController.text) ?? data['singlePrice'],
                'multiPrice': double.tryParse(multiController.text) ?? data['multiPrice'],
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
