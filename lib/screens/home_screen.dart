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

  // أسعار الساعة الافتراضية
  final double singleRatePerHour = 30.0;
  final double multiRatePerHour = 50.0;

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
            return const Center(child: Text('لا توجد أجهزة متوفرة'));
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isBusy = data['isBusy'] ?? false;
              final String currentMode = data['playMode'] ?? 'Single';

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
                  padding: const EdgeInsets.all(10.0),
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
                            size: 28,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBusy ? Colors.red : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBusy ? 'مشغول ($currentMode)' : 'متاح',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'جهاز',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text('النوع: ${data['type'] ?? 'PS4'}'),
                          if (isBusy) ...[
                            Text('سنجل: ${_formatSeconds(data['singleSeconds'] ?? 0)}'),
                            Text('ملتي: ${_formatSeconds(data['multiSeconds'] ?? 0)}'),
                          ],
                        ],
                      ),
                      Column(
                        children: [
                          if (isBusy)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade800,
                                minimumSize: const Size(double.infinity, 32),
                              ),
                              onPressed: () => _manageActiveSessionDialog(doc.id, data),
                              child: const Text('تحويل (سنجل/ملتي)', style: TextStyle(fontSize: 12)),
                            ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBusy ? Colors.red : Colors.green,
                              minimumSize: const Size(double.infinity, 36),
                            ),
                            onPressed: () {
                              if (isBusy) {
                                _checkoutSessionDialog(doc.id, data);
                              } else {
                                _startSessionDialog(doc.id, data['name'] ?? 'جهاز');
                              }
                            },
                            child: Text(isBusy ? 'إنهاء وحساب' : 'بدء الجلسة'),
                          ),
                        ],
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

  // تنسيق الثواني إلى دقيقة:ثانية
  String _formatSeconds(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // بدء الجلسة
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
              const Text('اختر نظام اللعب الابتدائي:'),
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
                  'lastModeSwitchTime': DateTime.now().millisecondsSinceEpoch,
                  'singleSeconds': 0,
                  'multiSeconds': 0,
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

  // التبديل بين الفردي والزوجي أثناء الجلسة
  void _manageActiveSessionDialog(String docId, Map<String, dynamic> data) {
    String currentMode = data['playMode'] ?? 'Single';
    String newMode = currentMode == 'Single' ? 'Multi' : 'Single';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تبديل وضع اللعب (${data['name']})'),
        content: Text('الوضع الحالي: $currentMode\nهل تريد التحويل إلى: $newMode ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              int now = DateTime.now().millisecondsSinceEpoch;
              int lastSwitch = data['lastModeSwitchTime'] ?? now;
              int diffSeconds = ((now - lastSwitch) / 1000).round();

              int singleSecs = data['singleSeconds'] ?? 0;
              int multiSecs = data['multiSeconds'] ?? 0;

              if (currentMode == 'Single') {
                singleSecs += diffSeconds;
              } else {
                multiSecs += diffSeconds;
              }

              await _firestore.collection('devices').doc(docId).update({
                'playMode': newMode,
                'lastModeSwitchTime': now,
                'singleSeconds': singleSecs,
                'multiSeconds': multiSecs,
              });

              if (mounted) Navigator.pop(context);
            },
            child: Text('تحويل إلى $newMode'),
          ),
        ],
      ),
    );
  }

  // إنهاء الجلسة، الحساب وتحديد كاش أو فيزا
  void _checkoutSessionDialog(String docId, Map<String, dynamic> data) {
    int now = DateTime.now().millisecondsSinceEpoch;
    int lastSwitch = data['lastModeSwitchTime'] ?? now;
    int diffSeconds = ((now - lastSwitch) / 1000).round();

    int totalSingleSecs = data['singleSeconds'] ?? 0;
    int totalMultiSecs = data['multiSeconds'] ?? 0;

    if ((data['playMode'] ?? 'Single') == 'Single') {
      totalSingleSecs += diffSeconds;
    } else {
      totalMultiSecs += diffSeconds;
    }

    double singleCost = (totalSingleSecs / 3600) * singleRatePerHour;
    double multiCost = (totalMultiSecs / 3600) * multiRatePerHour;
    double calculatedTotal = singleCost + multiCost;

    final amountController = TextEditingController(text: calculatedTotal.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إنهاء الجلسة - ${data['name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('مدة الفردي: ${_formatSeconds(totalSingleSecs)} (${singleCost.toStringAsFixed(1)} ج.م)'),
                Text('مدة الزوجي: ${_formatSeconds(totalMultiSecs)} (${multiCost.toStringAsFixed(1)} ج.م)'),
                const Divider(),
                const Text('المبلغ النهائي (يمكنك التعديل):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixText: 'ج.م',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('كاش 💵'),
                  value: 'كاش',
                  groupValue: paymentMethod,
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
                ),
                RadioListTile<String>(
                  title: const Text('فيزا / إلكتروني 💳'),
                  value: 'فيزا',
                  groupValue: paymentMethod,
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
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
                double finalAmount = double.tryParse(amountController.text) ?? calculatedTotal;

                // تسجيل الفاتورة في Firestore
                await _firestore.collection('reports').add({
                  'deviceName': data['name'],
                  'singleTime': _formatSeconds(totalSingleSecs),
                  'multiTime': _formatSeconds(totalMultiSecs),
                  'amount': finalAmount,
                  'paymentMethod': paymentMethod,
                  'date': DateTime.now().toString(),
                });

                // تصفير الجهاز وإرجاعه لمتاح
                await _firestore.collection('devices').doc(docId).update({
                  'isBusy': false,
                  'playMode': 'Single',
                  'singleSeconds': 0,
                  'multiSeconds': 0,
                });

                if (mounted) Navigator.pop(context);
              },
              child: const Text('تأكيد وإغلاق الجلسة'),
            ),
          ],
        ),
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
                decoration: const InputDecoration(labelText: 'اسم/رقم الجهاز'),
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
                    'playMode': 'Single',
                    'singleSeconds': 0,
                    'multiSeconds': 0,
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
}
