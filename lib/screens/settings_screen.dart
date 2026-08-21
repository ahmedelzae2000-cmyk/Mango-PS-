import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedMode = 'فاتح (Light)';
  String _selectedBackground = 'افتراضي (Purple)';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // تحميل الإعدادات المحفوظة مسبقاً
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMode = prefs.getString('app_mode') ?? 'فاتح (Light)';
      _selectedBackground = prefs.getString('app_bg') ?? 'افتراضي (Purple)';
    });
  }

  // حفظ الإعدادات
  Future<void> _saveSettings(String mode, String bg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode);
    await prefs.setString('app_bg', bg);
    setState(() {
      _selectedMode = mode;
      _selectedBackground = bg;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والتخصيص'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'مظهر التطبيق (المود)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اختر مود التطبيق',
              ),
              items: ['فاتح (Light)', 'داكن (Dark)'].map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  _saveSettings(val, _selectedBackground);
                }
              },
            ),
            const SizedBox(height: 25),
            const Text(
              'خلفية التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedBackground,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اختر شكل الخلفية',
              ),
              items: ['افتراضي (Purple)', 'داكن أنيق', 'لون هادئ'].map((bg) {
                return DropdownMenuItem(value: bg, child: Text(bg));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  _saveSettings(_selectedMode, val);
                }
              },
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('معلومات النظام:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('اسم التطبيق: Mango PS v1'),
                  Text('العملة: الجنيه المصري (ج.م)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
