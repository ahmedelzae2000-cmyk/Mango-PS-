import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onSelectScreen;
  final int currentScreenIndex;

  const AppDrawer({
    super.key,
    this.onSelectScreen,
    this.currentScreenIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text(
                'مدير النظام',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              accountEmail: Text('نظام البلايستيشن والإدارة', style: TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.sports_esports, size: 40, color: Colors.deepPurple),
              ),
              decoration: BoxDecoration(color: Colors.deepPurple),
            ),
            _buildItem(context, 0, Icons.sports_esports, '1. الرئيسية (الأجهزة)', '/home'),
            _buildItem(context, 1, Icons.timer, '2. إدارة الورديات', '/shift'),
            _buildItem(context, 2, Icons.money_off, '3. المصاريف والسلف', '/expenses'),
            _buildItem(context, 3, Icons.restaurant_menu, '4. بوفيه والمشروبات', '/buffet'),
            _buildItem(context, 4, Icons.sell, '5. تعديل الأسعار والأجهزة', '/pricing'),
            _buildItem(context, 5, Icons.bar_chart, '6. التقارير المالية', '/reports'),
            _buildItem(context, 6, Icons.settings, '7. الإعدادات', '/settings'),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, IconData icon, String title, String routeName) {
    final isSelected = currentScreenIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.withOpacity(0.3),
      leading: Icon(icon, color: isSelected ? Colors.deepPurpleAccent : Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.deepPurpleAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // إغلاق القائمة
        if (onSelectScreen != null) {
          onSelectScreen!(index);
        } else {
          // في حال تم استدعاؤه من شاشة فردية بدون MainLayout
          if (ModalRoute.of(context)?.settings.name != routeName) {
            Navigator.pushReplacementNamed(context, routeName);
          }
        }
      },
    );
  }
}
