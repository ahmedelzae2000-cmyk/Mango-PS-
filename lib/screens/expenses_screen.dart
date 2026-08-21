import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_drawer.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'صيانة'; // صيانة / سلفة / أخرى

  // إضافة مصروف جديد
  void _addExpense(String userName) async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final note = _noteController.text.trim();

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة البيان والمبلغ بشكل صحيح')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('expenses').add({
      'title': title,
      'amount': amount,
      'category': _selectedCategory, // صيانة أو سلفة أو أخرى
      'note': note,
      'user': userName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _amountController.clear();
    _noteController.clear();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل المصروف بنجاح')),
      );
    }
  }

  // نافذة إضافة المصروف
  void _showAddExpenseDialog(String userName, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final textColor = isDarkMode ? Colors.white : Colors.black;
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF222222) : Colors.white,
              title: Text('تسجيل مصروف جديد', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: isDarkMode ? const Color(0xFF333333) : Colors.white,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'نوع المصروف',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
                      items: ['صيانة', 'سلفة', 'أخرى'].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(color: textColor)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: _selectedCategory == 'سلفة' ? 'اسم مستلم السلفة' : 'البيان (مثال: صيانة دراع / فواتير)',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'المبلغ (ج.م)',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _noteController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'ملاحظات إضافية (اختياري)',
                        labelStyle: TextStyle(color: textColor),
                        border: const OutlineInputBorder(),
                      ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () => _addExpense(userName),
                  child: const Text('حفظ المصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // حساب أول يوم في الشهر الحالي للتقرير الشهري للسلف
  DateTime _getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1, 0, 0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDarkMode = appProvider.isDarkMode;
    final isAdmin = appProvider.userRole == 'مدير';

    // حماية الشاشة: يمنع دخول غير المدير
    if (!isAdmin) {
      return Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(title: const Text('المصاريف')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.redAccent),
              SizedBox(height: 15),
              Text(
                'عفواً، شاشة المصاريف مخصصة للمدير فقط!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final startOfMonth = _getStartOfMonth();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('إدارة المصاريف والسلف'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مصروف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddExpenseDialog(appProvider.userName.isEmpty ? 'المدير' : appProvider.userName, isDarkMode),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // كارت تقرير السلف الشهري
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .where('category', isEqualTo: 'سلفة')
                  .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                  .snapshots(),
              builder: (context, snapshot) {
                double totalAdvancesThisMonth = 0.0;
                int advancesCount = 0;

                if (snapshot.hasData) {
                  advancesCount = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    totalAdvancesThisMonth += (doc['amount'] ?? 0.0).toDouble();
                  }
                }

                return Card(
                  color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقرير السلف لشهر (${DateFormat('MM-yyyy').format(DateTime.now())})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'عدد عمليات السلف: $advancesCount',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '${totalAdvancesThisMonth.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontSize: 18, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // قائمة عرض كشف المصاريف المضافة بالكامل
            const Text('سجل كافة المصاريف والسلف المسجلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text('لا توجد أي مصاريف مسجلة حتى الآن.')),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final Timestamp? time = data['timestamp'] as Timestamp?;
                    final String timeFormatted = time != null
                        ? DateFormat('yyyy-MM-dd | hh:mm a').format(time.toDate())
                        : 'جارِ التسجيل...';
                    final String category = data['category'] ?? 'أخرى';

                    // اختيار أيقونة بحسب النوع
                    IconData icon;
                    Color iconColor;
                    if (category == 'صيانة') {
                      icon = Icons.build;
                      iconColor = Colors.orange;
                    } else if (category == 'سلفة') {
                      icon = Icons.person_remove;
                      iconColor = Colors.purpleAccent;
                    } else {
                      icon = Icons.money_off;
                      iconColor = Colors.redAccent;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(icon, color: iconColor),
                        ),
                        title: Text(
                          '${data['title'] ?? ''} ($category)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('⏰ الوقت: $timeFormatted\n👤 بواسطة: ${data['user'] ?? 'غير محدد'}'
                            '${(data['note'] != null && data['note'].toString().isNotEmpty) ? '\n📝 ملاحظة: ${data['note']}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '-${(data['amount'] ?? 0.0).toStringAsFixed(2)} ج.م',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('expenses').doc(docs[index].id).delete();
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
}
