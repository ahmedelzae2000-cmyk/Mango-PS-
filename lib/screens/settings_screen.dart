import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDarkMode = appProvider.isDarkMode;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('الإعدادات والتخصيص'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAlignment: CrossAlignment.start,
          children: [
            // 1. قسم بيانات المستحدم الحالي
            Card(
              color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.amber),
                ),
                title: Text(
                  appProvider.userName.isNotEmpty ? appProvider.userName : 'المستخدم الحالي',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                subtitle: Text('الصلاحية: ${appProvider.userRole.isNotEmpty ? appProvider.userRole : "موظف"}'),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  label: const Text('خروج', style: TextStyle(color: Colors.redAccent)),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Text('🎨 المظهر والألوان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 2. مفتاح التبديل للوضع الليلي
            Card(
              color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
              child: SwitchListTile(
                title: const Text('الوضع الليلي (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('تغيير ألوان الشاشات للون الداكن المريح للعين'),
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: isDarkMode ? Colors.amber : Colors.orange,
                ),
                value: isDarkMode,
                onChanged: (val) {
                  appProvider.toggleDarkMode(val);
                },
              ),
            ),

            const SizedBox(height: 15),

            // 3. اختيار اللون الرئيسي للتطبيق
            Card(
              color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAlignment: CrossAlignment.start,
                children: [
                  const Text('اللون الرئيسي للتطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('اختر اللون المفضل للأزرار والشريط العلوي:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildColorOption(context, Colors.blue, 'أزرق', appProvider),
                      _buildColorOption(context, Colors.deepPurple, 'بنفسجي', appProvider),
                      _buildColorOption(context, Colors.teal, 'تايل', appProvider),
                      _buildColorOption(context, Colors.orange, 'برتقالي', appProvider),
                      _buildColorOption(context, Colors.redAccent, 'أحمر', appProvider),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text('ℹ️ عن التطبيق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Card(
              color: isDarkMode ? const Color(0xFF1E1E2C) : Colors.white,
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.videogame_asset, color: Colors.blueAccent),
                    title: Text('نظام إدارة بلايستيشن (PlayStation POS)'),
                    subtitle: Text('الإصدار 1.0.0'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.verified_user, color: Colors.green),
                    title: Text('حالة المزامنة والربط'),
                    subtitle: Text('متصل بالسحابة عبر Firebase Cloud Firestore'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, Color color, String name, AppProvider provider) {
    final isSelected = provider.primaryColor == color;
    return GestureDetector(
      onTap: () => provider.setPrimaryColor(color),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
