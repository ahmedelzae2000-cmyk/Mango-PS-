import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseDebugScreen(),
    );
  }
}

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  String _statusMessage = 'جاري محاولة الاتصال...';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _connectFirebase();
  }

  Future<void> _connectFirebase() async {
    try {
      // تمرير خيارات الفايربيس مباشرة لتجاوز خطأ values.xml نهائياً
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB5UujdLmnqFvmujV3FSwSH2iI0L-78jk4",
          appId: "1:603196411064:android:c0b7cd83ee50712d9ef84d",
          messagingSenderId: "603196411064",
          projectId: "mango-ps",
          storageBucket: "mango-ps.firebasestorage.app",
        ),
      );
      setState(() {
        _isSuccess = true;
        _statusMessage = '✅ تم الاتصال بـ Firebase بنجاح!';
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = '❌ فشل التهيئة بسبب:\n\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الفايربيس'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSuccess ? Icons.check_circle : Icons.error_outline,
                size: 80,
                color: _isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 20),
              SelectableText(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
