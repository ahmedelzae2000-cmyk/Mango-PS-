import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'موظف'; // الافتراضي موظف
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    onPressed: () {
                      final provider = Provider.of<DeviceProvider>(context, listen: false);

                      if (selectedRole == 'مدير') {
                        // باسورد المدير افتراضياً 1234 (يمكنك تغييره هنا)
                        if (passwordController.text == '1995') {
                          provider.setUserRole('مدير');
                          _goToHome(context);
                        } else {
                          _showError(context, 'كلمة مرور المدير غير صحيحة');
                        }
                      } else {
                        // لو موظف (ممكن تحط باسورد معين للموظف أو تسيبه فاضي لو ملوش باسورد)
                        // هنا هفترض إن الموظف بیدخل مباشرة أو بـ باسورد مثل 111
                        provider.setUserRole('موظف');
                        _goToHome(context);
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
