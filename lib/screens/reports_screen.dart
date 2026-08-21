import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDailyDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // بداية الشهر الحالي
  DateTime _getStartOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1, 0, 0, 0);
  }

  // اختيار تاريخ للتقرير اليومي
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDailyDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDailyDate) {
      setState(() {
        _selectedDailyDate = picked;
      });
    }
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
        appBar: AppBar(title: const Text('التقارير المالية')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.redAccent),
              SizedBox(height: 15),
              Text(
                'عفواً، شاشة التقارير مخصصة للمدير فقط!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'تقرير شهري (الورديات)'),
            Tab(icon: Icon(Icons.today), text: 'تقرير يومي مفصل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. التبويب الأول: التقرير الشهري بالورديات
          _buildMonthlyReportTab(isDarkMode),

          // 2. التبويب الثاني: التقرير اليومي المفصل
          _buildDailyReportTab(isDarkMode),
        ],
      ),
    );
  }

  // ==================== ويدجت التقرير الشهري ====================
  Widget _buildMonthlyReportTab(bool isDarkMode) {
    final startOfMonth = _getStartOfCurrentMonth();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shifts')
          .where('scheduledShiftStart', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .orderBy('scheduledShiftStart', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        double monthlyTotalCash = 0.0;
        double monthlyTotalVisa = 0.0;
        double monthlyTotalExpenses = 0.0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          monthlyTotalCash += (data['totalCash'] ?? 0.0).toDouble();
          monthlyTotalVisa += (data['totalVisa'] ?? 0.0).toDouble();
          monthlyTotalExpenses += (data['totalExpenses'] ?? 0.0).toDouble();
        }

        final monthlyTotalIncome = monthlyTotalCash + monthlyTotalVisa;
        final monthlyNetProfit = monthlyTotalIncome - monthlyTotalExpenses;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              // كارت تجميعي إجمالي الشهر
              Card(
                color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'إجمالي دخل الشهر (${DateFormat('MM-yyyy').format(DateTime.now())})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(child: _buildSummaryItem('💵 كاش', '${monthlyTotalCash.toStringAsFixed(2)} ج.م', Colors.green)),
                          Expanded(child: _buildSummaryItem('💳 فيزا', '${monthlyTotalVisa.toStringAsFixed(2)} ج.م', Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildSummaryItem('🔻 المصاريف', '${monthlyTotalExpenses.toStringAsFixed(2)} ج.م', Colors.red)),
                          Expanded(child: _buildSummaryItem('📈 صافي الأرباح', '${monthlyNetProfit.toStringAsFixed(2)} ج.م', Colors.amber)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('سجل ورديات الشهر بالتواريخ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (docs.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('لا توجد ورديات مسجلة لهذا الشهر.'))))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final Timestamp? shiftTime = data['scheduledShiftStart'] as Timestamp?;
                    final dateStr = shiftTime != null ? DateFormat('yyyy-MM-dd').format(shiftTime.toDate()) : 'غير محدد';
                    final status = data['status'] == 'open' ? 'مفتوحة' : 'مغلقة';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('📅 وردية يوم: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: data['status'] == 'open' ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(status, style: TextStyle(color: data['status'] == 'open' ? Colors.green : Colors.grey, fontSize: 12)),
                                ),
                              ],
                            ),
                            Text('👤 الموظف: ${data['employeeName'] ?? ''}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('💵 كاش: ${(data['totalCash'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                                Text('💳 فيزا: ${(data['totalVisa'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue)),
                                Text('🔻 مصاريف: ${(data['totalExpenses'] ?? 0.0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ==================== ويدجت التقرير اليومي المفصل ====================
  Widget _buildDailyReportTab(bool isDarkMode) {
    final startOfDay = DateTime(_selectedDailyDate.year, _selectedDailyDate.month, _selectedDailyDate.day, 0, 0, 0);
    final endOfDay = DateTime(_selectedDailyDate.year, _selectedDailyDate.month, _selectedDailyDate.day, 23, 59, 59);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          // شريط اختيار التاريخ اليومي
          Card(
            color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
            child: ListTile(
              leading: const Icon(Icons.event, color: Colors.amber),
              title: Text('عرض تقرير يوم: ${DateFormat('yyyy-MM-dd').format(_selectedDailyDate)}'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () => _selectDate(context),
                child: const Text('تغيير اليوم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 1. تفاصيل جلسات هذا اليوم بالوقت والدقيقة
          const Text('🎮 جلسات اللعب خلال اليوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sessions')
                .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(12.0), child: Text('لا توجد جلسات مسجلة في هذا اليوم.')));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final Timestamp? time = data['timestamp'] as Timestamp?;
                  final timeStr = time != null ? DateFormat('hh:mm a').format(time.toDate()) : '';
                  final method = data['paymentMethod'] ?? 'كاش';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(method == 'فيزا' ? Icons.credit_card : Icons.money, color: method == 'فيزا' ? Colors.blue : Colors.green),
                      title: Text('${data['deviceName'] ?? ''} (${data['sessionType'] ?? ''})'),
                      subtitle: Text('⏰ الوقت: $timeStr | المدة: ${data['duration'] ?? ''} | طريقة الدفع: $method'),
                      trailing: Text('${(data['cost'] ?? 0.0).toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // 2. تفاصيل مصاريف هذا اليوم بالوقت
          const Text('💸 المصاريف المسجلة خلال اليوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expenses')
                .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(12.0), child: Text('لا توجد مصاريف مسجلة في هذا اليوم.')));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final Timestamp? time = data['timestamp'] as Timestamp?;
                  final timeStr = time != null ? DateFormat('hh:mm a').format(time.toDate()) : '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.money_off, color: Colors.redAccent),
                      title: Text('${data['title'] ?? ''} (${data['category'] ?? 'مصروف'})'),
                      subtitle: Text('⏰ الوقت: $timeStr | بواسطة: ${data['user'] ?? ''}'),
                      trailing: Text('-${(data['amount'] ?? 0.0).toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
