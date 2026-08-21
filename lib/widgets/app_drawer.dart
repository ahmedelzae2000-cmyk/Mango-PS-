import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/home_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/pricing_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/shift_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                appProvider.userName.isNotEmpty ? appProvider.userName : 'المستخدم',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              accountEmail: Text(
                'الصلاحية: ${appProvider.userRole}',
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.sports_esports, size: 40, color: Colors.black87),
              ),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: Colors.white),
                    title: const Text('الرئيسية (الأجهزة)', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.white),
                    title: const Text('إدارة الورديات', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ShiftScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.money_off, color: Colors.white),
                    title: const Text('المصاريف والسلف', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ExpensesScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sell, color: Colors.white),
                    title: const Text('تعديل الأسعار والأجهزة', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const PricingScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.white),
                    title: const Text('التقارير المالية', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ReportsScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context); // إغلاق القائمة أولاً
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
