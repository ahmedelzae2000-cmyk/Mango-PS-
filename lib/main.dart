import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const MangoPSApp());
}

class MangoPSApp extends StatelessWidget {
  const MangoPSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mango PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E24),
        primaryColor: Colors.deepOrange,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrange,
          secondary: Colors.deepOrangeAccent,
          surface: Color(0xFF1E1E24),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DevicesScreen(),
      const ExpensesScreen(),
      const ShiftScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.jpg',
                height: 32,
                width: 32,
                errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports, color: Colors.deepOrange),
              ),
            ),
            const SizedBox(width: 10),
            const Text('MANGO PS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        backgroundColor: const Color(0xFF18181C),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.85),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF121212)),
            ),
          ),
          screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF18181C),
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'الأجهزة'),
          BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'المصاريف'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'الوردية'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// 1. شاشة الأجهزة (مع التوقيت وحساب التكلفة)
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  void _toggleSession(BuildContext context, String docId, Map<String, dynamic> data) async {
    final isRunning = data['isRunning'] ?? false;

    if (!isRunning) {
      // بدء الجلسة
      await FirebaseFirestore.instance.collection('devices').doc(docId).update({
        'isRunning': true,
        'startTime': FieldValue.serverTimestamp(),
        'mode': 'single', // الافتراضي سنجل
      });
    } else {
      // إنهاء الجلسة وحساب الحساب
      Timestamp? startTimestamp = data['startTime'];
      DateTime startTime = startTimestamp?.toDate() ?? DateTime.now();
      DateTime endTime = DateTime.now();
      Duration duration = endTime.difference(startTime);

      double rate = (data['mode'] == 'multi') 
          ? (data['multiRate'] ?? 0.0).toDouble() 
          : (data['singleRate'] ?? 0.0).toDouble();

      double hours = duration.inMinutes / 60.0;
      double totalCost = hours * rate;

      // إيقاف الجهاز
      await FirebaseFirestore.instance.collection('devices').doc(docId).update({
        'isRunning': false,
        'startTime': null,
      });

      // حفظ الجلسة في الحسابات
      await FirebaseFirestore.instance.collection('sessions').add({
        'deviceName': data['name'],
        'durationMinutes': duration.inMinutes,
        'amount': totalCost,
        'timestamp': FieldValue.serverTimestamp(),
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Text('إنهاء جلسة ${data['name']}'),
          content: Text('الوقت: ${duration.inMinutes} دقيقة\nالمبلغ المطلوبة: ${totalCost.toStringAsFixed(2)} ج.م'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تم', style: TextStyle(color: Colors.deepOrange)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('devices').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('خطأ في الاتصال بالخادم', style: TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد أجهزة، ضف من الإعدادات', style: TextStyle(color: Colors.grey)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final docId = docs[index].id;
            final data = docs[index].data() as Map<String, dynamic>;
            final isRunning = data['isRunning'] ?? false;
            final mode = data['mode'] ?? 'single';

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isRunning ? Colors.green : Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(data['type'] ?? 'PS4', style: const TextStyle(color: Colors.deepOrange)),
                    if (isRunning) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('سنجل', style: TextStyle(fontSize: 10)),
                            selected: mode == 'single',
                            onSelected: (_) => FirebaseFirestore.instance.collection('devices').doc(docId).update({'mode': 'single'}),
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('ملتي', style: TextStyle(fontSize: 10)),
                            selected: mode == 'multi',
                            onSelected: (_) => FirebaseFirestore.instance.collection('devices').doc(docId).update({'mode': 'multi'}),
                          ),
                        ],
                      ),
                    ],
                    Text(isRunning ? 'شغال' : 'متاح', style: TextStyle(color: isRunning ? Colors.green : Colors.grey)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isRunning ? Colors.red : Colors.green),
                      onPressed: () => _toggleSession(context, docId, data),
                      child: Text(isRunning ? 'إنهاء وحساب' : 'بدء الجلسة', style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 2. شاشة المصاريف
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  void _addExpense() async {
    if (_titleController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      final double? amount = double.tryParse(_amountController.text);
      if (amount != null) {
        await FirebaseFirestore.instance.collection('expenses').add({
          'title': _titleController.text,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _titleController.clear();
        _amountController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'سبب المصروف (مثلاً: صيانات أو شاي)'),
                ),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('تسجيل المصروف', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerRight,
            child: Text('المصروفات المسجلة اليوم:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('expenses').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ أثناء الاتصال', style: TextStyle(color: Colors.redAccent)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد مصروفات مسجلة اليوم', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: const Color(0xFF1E1E24).withOpacity(0.9),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.money_off, color: Colors.redAccent),
                        title: Text(data['title'] ?? ''),
                        trailing: Text('${data['amount']} ج.م', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
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
}

// 3. شاشة الوردية (حساب إجمالي الأجهزة والمصاريف تلقائياً)
class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sessions').snapshots(),
      builder: (context, sessionSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
          builder: (context, expenseSnap) {
            double totalIncome = 0.0;
            double totalExpenses = 0.0;

            if (sessionSnap.hasData) {
              for (var doc in sessionSnap.data!.docs) {
                totalIncome += (doc['amount'] ?? 0.0).toDouble();
              }
            }

            if (expenseSnap.hasData) {
              for (var doc in expenseSnap.data!.docs) {
                totalExpenses += (doc['amount'] ?? 0.0).toDouble();
              }
            }

            double netTotal = totalIncome - totalExpenses;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: const Color(0xFF1E1E24).withOpacity(0.9),
                    child: const ListTile(
                      title: Text('توقيت الوردية الحالية'),
                      subtitle: Text('من 12:00 ظهراً إلى 12:00 ظهراً اليوم التالي'),
                      trailing: Icon(Icons.timer, color: Colors.deepOrange),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('إجمالي الأجهزة', '${totalIncome.toStringAsFixed(1)} ج.م', Colors.green)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInfoCard('المصروفات', '${totalExpenses.toStringAsFixed(1)} ج.م', Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('الصافي الحالي', '${netTotal.toStringAsFixed(1)} ج.م', Colors.deepOrange)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// 4. شاشة التقارير
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'التقرير اليومي (مفصل)'),
              Tab(text: 'التقرير الشهري (ملخص)'),
            ],
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                const Center(child: Text('لا توجد جلسات مسجلة اليوم')),
                const Center(child: Text('لا توجد ورديات سابقة هذا الشهر')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 5. شاشة الإعدادات والأسعار
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceNameController = TextEditingController();
  final _singleRateController = TextEditingController();
  final _multiRateController = TextEditingController();
  String _selectedType = 'PS4';

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: const Text('إضافة جهاز جديد', style: TextStyle(color: Colors.deepOrange)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(labelText: 'اسم الجهاز (مثلاً: جهاز 1)'),
              ),
              DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E24),
                items: ['PS4', 'PS5'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => _selectedType = val);
                  }
                },
              ),
              TextField(
                controller: _singleRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر الساعة سنجل (ج.م)'),
              ),
              TextField(
                controller: _multiRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سعر الساعة ملتي (ج.م)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () async {
                if (_deviceNameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('devices').add({
                    'name': _deviceNameController.text,
                    'type': _selectedType,
                    'singleRate': double.tryParse(_singleRateController.text) ?? 0.0,
                    'multiRate': double.tryParse(_multiRateController.text) ?? 0.0,
                    'isRunning': false,
                  });
                  _deviceNameController.clear();
                  _singleRateController.clear();
                  _multiRateController.clear();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ الجهاز', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPriceDialog(String docId, String currentName, double currentSingle, double currentMulti) {
    final singleCtrl = TextEditingController(text: currentSingle.toString());
    final multiCtrl = TextEditingController(text: currentMulti.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text('تعديل سعر $currentName', style: const TextStyle(color: Colors.deepOrange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: singleCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر السنجل الجديد'),
            ),
            TextField(
              controller: multiCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر الملتي الجديد'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('devices').doc(docId).update({
                'singleRate': double.tryParse(singleCtrl.text) ?? currentSingle,
                'multiRate': double.tryParse(multiCtrl.text) ?? currentMulti,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('تحديث السعر', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(String docId) async {
    await FirebaseFirestore.instance.collection('devices').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.all(12)),
            onPressed: _showAddDeviceDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة جهاز جديد', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const SizedBox(height: 20),
          const Text('قائمة الأجهزة والأسعار الحالية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('devices').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ أثناء تحميل البيانات', style: TextStyle(color: Colors.redAccent)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد أجهزة مسجلة حالياً', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final name = data['name'] ?? 'جهاز';
                    final type = data['type'] ?? 'PS4';
                    final singleRate = (data['singleRate'] ?? 0.0).toDouble();
                    final multiRate = (data['multiRate'] ?? 0.0).toDouble();

                    return Card(
                      color: const Color(0xFF1E1E24).withOpacity(0.9),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('$name ($type)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('سنجل: $singleRate ج.م | ملتي: $multiRate ج.م'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.deepOrange),
                              onPressed: () => _showEditPriceDialog(docId, name, singleRate, multiRate),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteDevice(docId),
                            ),
                          ],
                        ),
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
}
