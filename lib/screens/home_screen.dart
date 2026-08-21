import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('الرئيسية - أجهزة البلايستيشن'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('devices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد أجهزة، اضغط على + لإضافة جهاز'));
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isBusy = data['isBusy'] ?? false;

              return Card(
                color: isBusy
                    ? Colors.red.shade900.withOpacity(0.3)
                    : Colors.green.shade900.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isBusy ? Colors.red : Colors.green,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.sports_esports,
                            color: isBusy ? Colors.red : Colors.green,
                            size: 30,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBusy ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBusy ? 'مشغول' : 'متاح',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'جهاز',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('النوع: ${data['type'] ?? 'PS4'}'),
                          Text('الوقت: ${data['elapsedTime'] ?? '00:00'}'),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBusy ? Colors.red : Colors.green,
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        onPressed: () {
                          if (isBusy) {
                            _endSession(doc.id);
                          } else {
                            _startSessionDialog(doc.id, data['name'] ?? 'جهاز');
                          }
                        },
                        child: Text(isBusy ? 'إنهاء الجلسة' : 'بدء الجلسة'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDeviceDialog() {
    final nameController = TextEditingController();
    String selectedType = 'PS4';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة جهاز جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم/رقم الجهاز (مثال: جهاز 2)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ['PS4', 'PS5', 'VIP']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: 'نوع الجهاز'),
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
                if (nameController.text.isNotEmpty) {
                  await _firestore.collection('devices').add({
                    'name': nameController.text,
                    'type': selectedType,
                    'isBusy': false,
                    'elapsedTime': '00:00',
                  });
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _startSessionDialog(String docId, String deviceName) {
    String selectedMode = 'Single';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('بدء جلسة - $deviceName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر نوع اللعب:'),
              RadioListTile<String>(
                title: const Text('فردي (Single)'),
                value: 'Single',
                groupValue: selectedMode,
                onChanged: (val) => setDialogState(() => selectedMode = val!),
              ),
              RadioListTile<String>(
                title: const Text('زوجي (Multi)'),
                value: 'Multi',
                groupValue: selectedMode,
                onChanged: (val) => setDialogState(() => selectedMode = val!),
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
                  'isBusy': true,
                  'playMode': selectedMode,
                  'startTime': FieldValue.serverTimestamp(),
                  'elapsedTime': '00:00',
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('تأكيد البدء'),
            ),
          ],
        ),
      ),
    );
  }

  void _endSession(String docId) async {
    await _firestore.collection('devices').doc(docId).update({
      'isBusy': false,
      'elapsedTime': '00:00',
    });
  }
}
