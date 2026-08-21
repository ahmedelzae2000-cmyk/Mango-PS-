import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/device_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);

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
              value: provider.appMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اختر مود التطبيق',
              ),
              items: ['فاتح (Light)', 'داكن (Dark)'].map((mode) {
                return DropdownMenuItem(value: mode, child: Text(mode));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  provider.updateSettings(val, provider.backgroundType);
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
              value: provider.backgroundType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اختر شكل الخلفية',
              ),
              items: ['افتراضي (Purple)', 'داكن أنيق', 'لون هادئ', 'صورة مخصصة'].map((bg) {
                return DropdownMenuItem(value: bg, child: Text(bg));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  provider.updateSettings(provider.appMode, val);
                }
              },
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              icon: const Icon(Icons.image),
              label: const Text('اختيار خلفية مخصصة من الهاتف'),
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  await provider.updateSettings(provider.appMode, 'صورة مخصصة', imagePath: image.path);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم اختيار الخلفية بنجاح')),
                    );
                  }
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
                  Text('اسم التطبيق: Manga PS v1'),
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
