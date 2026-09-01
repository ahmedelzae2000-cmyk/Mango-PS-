import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/device_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'موظف';
  final passwordController = TextEditingController();

  // دالة حفظ حالة تسجيل الدخول في التخزين المحلي
  Future<void> _saveLoginState(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_role', role);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. عرض الخلفية المحددة في الإعدادات
          _buildBackground(provider),

          // 2. محتوى شاشة تسجيل الدخول
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.9), // طبقة شفافة لتسهيل القراءة
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gamepad, size: 80, color: Colors.deepPurple),
                      const SizedBox(height: 16),
                      const Text(
                        'Manga PS',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 30),
                      
                      // اختيار الدور (موظف ولا مدير)
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'موظف', label: Text('موظف'), icon: Icon(Icons.person)),
                          ButtonSegment(value: 'مدير', label: Text('مدير'), icon: Icon(Icons.admin_panel_settings)),
                        ],
                        selected: {selectedRole},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            selectedRole = newSelection.first;
                            passwordController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 25),

                      // خانة الباسورد
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: selectedRole == 'مدير' ? 'كلمة مرور المدير' : 'كلمة مرور الموظف (إن وجدت)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // زر الدخول
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final devProvider = Provider.of<DeviceProvider>(context, listen: false);

                            if (selectedRole == 'مدير') {
                              if (passwordController.text == '1995') {
                                await devProvider.setUserRole('مدير');
                                await _saveLoginState('مدير');
                                if (context.mounted) _goToHome(context);
                              } else {
                                _showError(context, 'كلمة مرور المدير غير صحيحة');
                              }
                            } else {
                              await devProvider.setUserRole('موظف');
                              await _saveLoginState('موظف');
                              if (context.mounted) _goToHome(context);
                            }
                          },
                          child: Text('دخول بصفة ($selectedRole)', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة بناء خلفية الشاشة بناءً على الإعدادات
  Widget _buildBackground(DeviceProvider provider) {
    if (provider.backgroundType == 'صورة شخصية' && provider.customImagePath != null) {
      final file = File(provider.customImagePath!);
      if (file.existsSync()) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }
    
    // خلفية افتراضية في حالة عدم وجود صورة شخصية
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
