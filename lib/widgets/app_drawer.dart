import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/home_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/shifts_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isAdmin = appProvider.userRole == 'مدير';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              appProvider.userName.isNotEmpty ? appProvider.userName : 'مستخدم',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('الرتبة: ${appProvider.userRole}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blueGrey),
            ),
            decoration: const BoxDecoration(color: Color(0xFF1E1E2C)),
          ),
          ListTile(
            leading: const Icon(Icons.sports_esports),
            title: const Text('الأجهزة والعدادات (الرئيسية)'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('الورديات'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ShiftsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.money_off),
            title: const Text('المصاريف'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesScreen()),
            ),
          ),
          if (isAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('إدارة الأجهزة والأسعار'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DevicesScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('التقارير المالية'),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('الإعدادات والمظهر'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
