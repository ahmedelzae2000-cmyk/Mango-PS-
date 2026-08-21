import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // 1. تأكيد جاهزية محرك الفلاتر
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. انتهاء التهيئة أولاً وقبل تشغيل التطبيق
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseStatusCheck(),
    );
  }
}

class FirebaseStatusCheck extends StatelessWidget {
  const FirebaseStatusCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الفايربيس'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        // التأكد المباشر من وجود تطبيق الفايربيس
        future: Future.value(Firebase.apps.isNotEmpty),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data == true) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 90, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    '✅ تم ربط الفايربيس بنجاح!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 90, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  '❌ الفايربيس غير متصل',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
