import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
// استبدل المسار ده بالشاشة الرئيسية عندك (مثلا Home أو Dashboard)
// import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isAdminMode = false;

  void _login(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context, listen: false);

    if (_isAdminMode) {
      // كلمة سر المدير (يمكنك تغييرها كما تحب أو ربطها بقاعدة بيانات)
      if (_passwordController.text == '1234') {
        provider.setUserRole('مدير');
        _navigateToHome(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كلمة مرور المدير غير صحيحة!'), backgroundColor: Colors.red),
        );
      }
    } else {
      // الدخول كموظف عادي
      provider.setUserRole('موظف');
      _navigateToHome(context);
    }
  }

  void _navigateToHome(BuildContext context) {
    // الانتقال للشاشة الرئيسية بعد تسجيل الدخول
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    Navigator.pop(context); // أو العودة لو الشاشة عبارة عن صفحة إعدادات/تسجيل
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول والنظام'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                const Text(
                  'اختر نمط الدخول للنظام',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                // اختيار الدور
                ToggleButtons(
                  isSelected: [!_isAdminMode, _isAdminMode],
                  onPressed: (index) {
                    setState(() {
                      _isAdminMode = index == 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  selectedColor: Colors.white,
                  fillColor: Colors.deepPurple,
                  color: Colors.black,
                  constraints: const BoxConstraints(minHeight: 50, minWidth: 130),
                  children: const [
                    Text('موظف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('مدير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 30),

                // إظهار حقل كلمة السر فقط إذا كان المدير
                if (_isAdminMode) ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'كلمة مرور المدير',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleNumbers.roundedRectangleBorder 
                          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)) 
                          : null,
                    ),
                    onPressed: () => _login(context),
                    child: const Text('دخول للنظام', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
