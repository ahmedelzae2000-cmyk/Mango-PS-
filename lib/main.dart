import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/device_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // تهيئة الفايربيس بنفس الخيارات المضمونة
      future: Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB5UujdLmnqFvmujV3FSwSH2iI0L-78jk4",
          appId: "1:603196411064:android:c0b7cd83ee50712d9ef84d",
          messagingSenderId: "603196411064",
          projectId: "mango-ps",
          storageBucket: "mango-ps.firebasestorage.app",
        ),
      ),
      builder: (context, snapshot) {
        // شاشة تحميل بسيطة أثناء الاتصال بالفايربيس
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // في حالة وجود خطأ
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text('خطأ في الاتصال: ${snapshot.error}'),
              ),
            ),
          );
        }

        // بعد النجاح: تشغيل التطبيق بالـ Providers والواجهة الرئيسية
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DeviceProvider()),
          ],
          child: MaterialApp(
            title: 'Manga PS',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar', ''),
            ],
            locale: const Locale('ar', ''),
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
