import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_drawer.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  // للتحكم في مدخلات التعديل الجماعي
  final _ps4SingleCtrl = TextEditingController(text: '30');
  final _ps4MultiCtrl = TextEditingController(text: '40');
  final _ps5SingleCtrl = TextEditingController(text: '50');
  final _ps5MultiCtrl = TextEditingController(text: '70');

  // للتحكم في إضافة جهاز جديد
  final _deviceNameCtrl = TextEditingController();
  final _newSinglePriceCtrl = TextEditingController(text: '30');
  final _newMultiPriceCtrl = TextEditingController(text: '40');
  String _selectedType = 'PS4';

  // دالة تحديث أسعار فئة كاملة (مثل كل أجهزة PS4 أو كل أجهزة PS5)
  Future<void> _updateCategoryPrices(String category, double singlePrice, double multiPrice) async {
    final collection = FirebaseFirestore.instance.collection('devices');
    final query = await collection.where('type', isEqualTo: category).get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {
        'singlePrice': singlePrice,
        'multiPrice': multiPrice,
      });
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث أسعار أجهزة $category بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // نافذة إضافة جهاز جديد
  void _showAddDeviceDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textColor = isDarkMode ? Colors.white : Colors.black;
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF222222) : Colors.white,
              title: Row(
                children: [
                  const Icon(Icons.add_to_queue, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text('إضافة جهاز جديد', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      dropdownColor: isDarkMode ? const Color(0xFF333333) : Colors.white,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'نوع الجهاز', border: OutlineInputBorder()),
                      items: ['PS4', 'PS5', 'VIP'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _deviceNameCtrl,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'اسم/رقم الجهاز (مثال: جهاز 6)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _newSinglePriceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'سعر السنجل/ساعة (ج.م)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _newMultiPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: const InputDecoration(labelText: 'سعر الملتي/ساعة (ج.م)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () async {
                    if (_deviceNameCtrl.text.trim().isEmpty) return;

                    await FirebaseFirestore.instance.collection('devices').add({
                      'name': _deviceNameCtrl.text.trim(),
                      'type': _selectedType,
                      'singlePrice': double.tryParse(_newSinglePriceCtrl.text) ?? 30.0,
                      'multiPrice': double.tryParse(_newMultiPriceCtrl.text) ?? 40.0,
                      'isOccupied': false,
                      'startTime': null,
                      'activePrice': 0.0,
                    });

                    _deviceNameCtrl.clear();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('إضافة الجهاز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // نافذة تعديل جهاز فردي
  void _showEditDeviceDialog(DocumentSnapshot doc, bool isDarkMode) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final singleCtrl = TextEditingController(text: (data['singlePrice'] ?? 30.0).toString());
    final multiCtrl = TextEditingController(text: (data['multiPrice'] ?? 40.0).toString());

    showDialog(
      context: context,
      builder: (context) {
        final textColor = isDarkMode ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF222222) : Colors.white,
          title: Text('تعديل: ${data['name']}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'اسم الجهاز', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: singleCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'سعر السنجل', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: multiCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(labelText: 'سعر الملتي', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('devices').doc(doc.id).update({
                  'name': nameCtrl.text.trim(),
                  'singlePrice': double.tryParse(singleCtrl.text) ?? 30.0,
                  'multiPrice': double.tryParse(multiCtrl.text) ?? 40.0,
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
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
    final isAdmin = appProvider.userRole == 'مدير';

    // حماية الشاشة للمدير فقط
    if (!isAdmin) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(title: const Text('إدارة الأسعار والأجهزة')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.redAccent),
              SizedBox(height: 15),
              Text('عفواً، هذه الشاشة مخصصة للمدير فقط!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('إدارة الأجهزة والأسعار'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة جهاز جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddDeviceDialog(isDarkMode),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            // 1. قسم التعديل السريع والتجميعي لأجهزة PS4 و PS5
            const Text('⚡ التعديل السريع لأسعار الفئات الكاملة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                // كارت PS4
                Expanded(
                  child: _buildCategoryPriceCard(
                    title: 'أجهزة PS4',
                    icon: Icons.sports_esports,
                    color: Colors.blue,
                    singleCtrl: _ps4SingleCtrl,
                    multiCtrl: _ps4MultiCtrl,
                    onSave: () {
                      final s = double.tryParse(_ps4SingleCtrl.text) ?? 30.0;
                      final m = double.tryParse(_ps4MultiCtrl.text) ?? 40.0;
                      _updateCategoryPrices('PS4', s, m);
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                // كارت PS5
                Expanded(
                  child: _buildCategoryPriceCard(
                    title: 'أجهزة PS5',
                    icon: Icons.gamepad,
                    color: Colors.deepPurpleAccent,
                    singleCtrl: _ps5SingleCtrl,
                    multiCtrl: _ps5MultiCtrl,
                    onSave: () {
                      final s = double.tryParse(_ps5SingleCtrl.text) ?? 50.0;
                      final m = double.tryParse(_ps5MultiCtrl.text) ?? 70.0;
                      _updateCategoryPrices('PS5', s, m);
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 2. قائمة كل الأجهزة الفردية المسجلة
            const Text('🖥️ قائمة كافة الأجهزة المضافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('devices').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text('لا توجد أجهزة مسجلة، اضغط على زر الإضافة بالأسفل.')),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String type = data['type'] ?? 'PS4';

                    Color typeColor = Colors.blue;
                    if (type == 'PS5') typeColor = Colors.deepPurpleAccent;
                    if (type == 'VIP') typeColor = Colors.amber;

                    return Card(
                      color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withOpacity(0.2),
                          child: Text(type, style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        title: Text(data['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        subtitle: Text('سنجل: ${data['singlePrice'] ?? 0} ج.م | ملتي: ${data['multiPrice'] ?? 0} ج.م'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showEditDeviceDialog(doc, isDarkMode),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('devices').doc(doc.id).delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت تصميم كارت تعديل الفئة (PS4 / PS5)
  Widget _buildCategoryPriceCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController singleCtrl,
    required TextEditingController multiCtrl,
    required VoidCallback onSave,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black;
    return Card(
      elevation: 4,
      color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 5),
            TextField(
              controller: singleCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'سنجل (ج.m)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: multiCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'ملتي (ج.m)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: onSave,
                child: const Text('تطبيق على الكل', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
