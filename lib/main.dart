import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
              child: Image.asset('assets/logo.jpg', height: 32, width: 32, errorBuilder: (_, __, ___) => const Icon(Icons.sports_esports, color: Colors.deepOrange)),
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
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'الوردية'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// 1. شاشة الأجهزة
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('devices').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد أجهزة مسجلة، ضف أجهزة من الإعدادات', style: TextStyle(color: Colors.grey)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isRunning = data['isRunning'] ?? false;

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isRunning ? Colors.green : Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(data['type'] ?? 'PS4', style: const TextStyle(color: Colors.deepOrange)),
                    Text(isRunning ? 'شغال' : 'متاح', style: TextStyle(color: isRunning ? Colors.green : Colors.grey)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: isRunning ? Colors.red : Colors.green),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('devices').doc(docs[index].id).update({'isRunning': !isRunning});
                      },
                      child: Text(isRunning ? 'إنهاء الجلسة' : 'بدء الجلسة', style: const TextStyle(color: Colors.white)),
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

// 2. شاشة الوردية (12 ظهراً لـ 12 ظهراً)
class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _buildInfoCard('كاش', '0 ج.م', Colors.green)),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoCard('انستا باي', '0 ج.م', Colors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildInfoCard('المصروفات', '0 ج.م', Colors.redAccent)),
              const SizedBox(width: 10),
              Expanded(child: _buildInfoCard('الصافي', '0 ج.م', Colors.deepOrange)),
            ],
          ),
        ],
      ),
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

// 3. شاشة التقارير
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

// 4. شاشة الإعدادات والأسعار
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('تعديل أسعار الأجهزة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          const SizedBox(height: 10),
          ListTile(
            tileColor: const Color(0xFF1E1E24).withOpacity(0.9),
            title: const Text('PS4 - سنجل / ملتي'),
            trailing: const Icon(Icons.edit, color: Colors.deepOrange),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: const Color(0xFF1E1E24).withOpacity(0.9),
            title: const Text('PS5 - سنجل / ملتي'),
            trailing: const Icon(Icons.edit, color: Colors.deepOrange),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.all(12)),
            onPressed: () {
              FirebaseFirestore.instance.collection('devices').add({
                'name': 'جهاز جديد',
                'type': 'PS5',
                'singleRate': 40.0,
                'multiRate': 60.0,
                'isRunning': false,
              });
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة جهاز جديد', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
