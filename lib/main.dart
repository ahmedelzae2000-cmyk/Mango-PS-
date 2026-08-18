import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDummyKeyForMangaPSApp",
        appId: "1:123456789:android:manga_ps",
        messagingSenderId: "123456789",
        projectId: "manga-ps-app",
        storageBucket: "manga-ps-app.appspot.com",
      ),
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const MangaPSApp());
}

class MangaPSApp extends StatefulWidget {
  const MangaPSApp({super.key});

  @override
  State<MangaPSApp> createState() => _MangaPSAppState();
}

class _MangaPSAppState extends State<MangaPSApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.deepOrange),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.deepOrange),
      home: SplashScreen(onToggleTheme: _toggleTheme),
    );
  }
}

// 1. شاشة ترحيبية (Splash Screen)
class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const SplashScreen({super.key, required this.onToggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainHomeScreen(onToggleTheme: widget.onToggleTheme)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg', height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.gamepad, size: 80, color: Colors.deepOrange)),
            const SizedBox(height: 20),
            const Text('مرحباً بكم في Manga PS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// نموذج البيانات للجهاز
class Device {
  String id;
  String name;
  String type; // PS4, PS5
  double singleRate;
  double multiRate;
  bool isMulti;
  bool isRunning;
  DateTime? startTime;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.singleRate,
    required this.multiRate,
    this.isMulti = false,
    this.isRunning = false,
    this.startTime,
  });
}

class MainHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainHomeScreen({super.key, required this.onToggleTheme});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  bool isShiftActive = false;
  DateTime? shiftStartTime;

  List<Device> devices = [
    Device(id: '1', name: 'جهاز (3)', type: 'PS5', singleRate: 40.0, multiRate: 60.0),
    Device(id: '2', name: 'جهاز (2)', type: 'PS5', singleRate: 40.0, multiRate: 60.0),
    Device(id: '3', name: 'جهاز (4)', type: 'PS4', singleRate: 30.0, multiRate: 40.0),
    Device(id: '4', name: 'جهاز 5', type: 'PS4', singleRate: 30.0, multiRate: 40.0),
    Device(id: '5', name: 'جهاز (1)', type: 'PS5', singleRate: 40.0, multiRate: 60.0),
  ];

  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> reports = [];

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildMainTab(),
      _buildExpensesTab(),
      _buildReportsTab(),
      _buildShiftTab(),
      _buildSettingsTab(),
    ];

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withOpacity(0.85) 
            : Colors.white.withOpacity(0.85),
        body: SafeArea(child: screens[_selectedIndex]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF18181C),
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'الأجهزة'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'المصروفات'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'الوردية'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  // 1. شاشة الرئيسية (تصميم الشبكة GridView)
  Widget _buildMainTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Manga PS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.sports_esports, color: Colors.grey, size: 28),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 30, color: Colors.white),
                onPressed: _showAddDeviceDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: GridView.builder(
              itemCount: devices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, i) {
                final d = devices[i];
                return Card(
                  color: const Color(0xFF232326),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () {
                                setState(() => devices.removeAt(i));
                              },
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            d.type,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const Text(
                          '00:00:00',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Text(
                          '0.00 ج.م',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF323238),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: d.isRunning ? null : () => setState(() => d.isMulti = true),
                                  child: Container(
                                    padding: const EdgeInsets.vertical(6),
                                    decoration: BoxDecoration(
                                      color: d.isMulti ? const Color(0xFF4A4A5A) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(child: Text('زوجي', style: TextStyle(fontSize: 12, color: Colors.white))),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: d.isRunning ? null : () => setState(() => d.isMulti = false),
                                  child: Container(
                                    padding: const EdgeInsets.vertical(6),
                                    decoration: BoxDecoration(
                                      color: !d.isMulti ? const Color(0xFF4A4A5A) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(child: Text('فردي', style: TextStyle(fontSize: 12, color: Colors.white))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: d.isRunning ? Colors.redAccent : const Color(0xFF4CAF50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              if (d.isRunning) {
                                _finishSessionDialog(d);
                              } else {
                                setState(() {
                                  d.isRunning = true;
                                  d.startTime = DateTime.now();
                                });
                              }
                            },
                            child: Text(
                              d.isRunning ? 'إيقاف' : 'تشغيل',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // إغلاق الفاتورة وتعديل الحساب يدوياً
  void _finishSessionDialog(Device d) {
    double baseRate = d.isMulti ? d.multiRate : d.singleRate;
    double calculatedAmount = baseRate; 
    double finalAmount = calculatedAmount;
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنهاء فاتورة ${d.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المحسوب: $calculatedAmount ج.م'),
            TextField(
              decoration: const InputDecoration(labelText: 'تعديل الحساب يدوياً (الصافي)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => finalAmount = double.tryParse(val) ?? calculatedAmount,
            ),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(value: 'كاش', child: Text('كاش')),
                DropdownMenuItem(value: 'فيزا', child: Text('فيزا')),
                DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
              ],
              onChanged: (val) => paymentMethod = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                d.isRunning = false;
                reports.add({
                  'title': 'جلسة ${d.name}',
                  'amount': finalAmount,
                  'method': paymentMethod,
                  'date': DateTime.now(),
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('حفظ واغلاق الفاتورة'),
          )
        ],
      ),
    );
  }

  // إضافة جهاز يدوي
  void _showAddDeviceDialog() {
    String name = '';
    String type = 'PS4';
    double sRate = 30.0;
    double mRate = 40.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهاز جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'اسم الجهاز (مثال: جهاز 6)'),
              onChanged: (val) => name = val,
            ),
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: 'PS4', child: Text('PS4')),
                DropdownMenuItem(value: 'PS5', child: Text('PS5')),
              ],
              onChanged: (val) => type = val!,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'سعر الفردي'),
              keyboardType: TextInputType.number,
              onChanged: (val) => sRate = double.tryParse(val) ?? 30.0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'سعر الزوجي (مالتي)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => mRate = double.tryParse(val) ?? 40.0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                setState(() {
                  devices.add(Device(
                    id: DateTime.now().toString(),
                    name: name,
                    type: type,
                    singleRate: sRate,
                    multiRate: mRate,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          )
        ],
      ),
    );
  }

  // 2. شاشة المصروفات
  Widget _buildExpensesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _showAddExpenseDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة مصروف جديد'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (ctx, i) => Card(
                child: ListTile(
                  title: Text(expenses[i]['title']),
                  trailing: Text('${expenses[i]['amount']} ج.م (${expenses[i]['method']})', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    String title = '';
    double amount = 0.0;
    String method = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مصروف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'البيان'),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: TextInputType.number,
              onChanged: (val) => amount = double.tryParse(val) ?? 0.0,
            ),
            DropdownButtonFormField<String>(
              value: method,
              items: const [
                DropdownMenuItem(value: 'كاش', child: Text('كاش')),
                DropdownMenuItem(value: 'فيزا', child: Text('فيزا')),
                DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
              ],
              onChanged: (val) => method = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty && amount > 0) {
                setState(() {
                  expenses.add({'title': title, 'amount': amount, 'method': method});
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          )
        ],
      ),
    );
  }

  // 3. شاشة التقارير (يومي مفصل وشهري مختصر)
  Widget _buildReportsTab() {
    final now = DateTime.now();
    final todayReports = reports.where((r) {
      final date = r['date'] as DateTime;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).toList();

    double todayIncome = todayReports.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    double todayExpensesSum = expenses.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    double todayNet = todayIncome - todayExpensesSum;

    final monthReports = reports.where((r) {
      final date = r['date'] as DateTime;
      return date.year == now.year && date.month == now.month;
    }).toList();

    double monthIncome = monthReports.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    double monthNet = monthIncome - todayExpensesSum;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'تقرير يومي مفصل', icon: Icon(Icons.today)),
              Tab(text: 'تقرير شهري مختصر', icon: Icon(Icons.calendar_month)),
            ],
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.purpleAccent,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. التقرير اليومي المفصل
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Card(
                        color: const Color(0xFF232326),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('الإيرادات', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text('$todayIncome ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('المصروفات', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text('$todayExpensesSum ج.م', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text('الصافي اليومي', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text('$todayNet ج.م', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text('تفاصيل المعاملات اليومية:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: todayReports.isEmpty
                            ? const Center(child: Text('لا توجد عمليات مسجلة اليوم', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: todayReports.length,
                                itemBuilder: (ctx, i) {
                                  final r = todayReports[i];
                                  final timeStr = DateFormat('hh:mm a').format(r['date']);
                                  return Card(
                                    color: const Color(0xFF1C1C1E),
                                    child: ListTile(
                                      leading: const Icon(Icons.sports_esports, color: Colors.purpleAccent),
                                      title: Text(r['title'], style: const TextStyle(color: Colors.white)),
                                      subtitle: Text('الوقت: $timeStr | طريقة الدفع: ${r['method']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      trailing: Text('+${r['amount']} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // 2. التقرير الشهري المختصر
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        color: const Color(0xFF232326),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                'ملخص شهر ${DateFormat('MMMM yyyy').format(now)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Divider(color: Colors.white24, height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('إجمالي الدخل الشهري:', style: TextStyle(fontSize: 15, color: Colors.white70)),
                                  Text('$monthIncome ج.م', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('إجمالي المصروفات:', style: TextStyle(fontSize: 15, color: Colors.white70)),
                                  Text('$todayExpensesSum ج.م', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الصافي النهائي للشهر:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber)),
                                  Text('$monthNet ج.م', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. شاشة الوردية
  Widget _buildShiftTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isShiftActive ? Icons.check_circle : Icons.pause_circle,
            size: 80,
            color: isShiftActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isShiftActive ? 'الوردية شغالة حالياً (12 ظهراً - 12 ظهراً)' : 'لا يوجد وردية مفتوحة',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isShiftActive ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                isShiftActive = !isShiftActive;
                shiftStartTime = isShiftActive ? DateTime.now() : null;
              });
            },
            child: Text(isShiftActive ? 'إنهاء الوردية' : 'بدء وردية جديدة يدوياً', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 5. شاشة إعدادات السعر للأجهزة
  Widget _buildSettingsTab() {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (ctx, i) {
        final d = devices[i];
        return Card(
          color: const Color(0xFF232326),
          child: ListTile(
            title: Text(d.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('فردي: ${d.singleRate} | زوجي: ${d.multiRate} ج.م', style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.amber),
              onPressed: () => _showEditRatesDialog(d),
            ),
          ),
        );
      },
    );
  }

  void _showEditRatesDialog(Device d) {
    double newSingle = d.singleRate;
    double newMulti = d.multiRate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل أسعار ${d.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'سعر الساعة (فردي)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => newSingle = double.tryParse(val) ?? d.singleRate,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'سعر الساعة (زوجي/مالتي)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => newMulti = double.tryParse(val) ?? d.multiRate,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                d.singleRate = newSingle;
                d.multiRate = newMulti;
              });
              Navigator.pop(ctx);
            },
            child: const Text('حفظ الأسعار'),
          )
        ],
      ),
    );
  }
}
