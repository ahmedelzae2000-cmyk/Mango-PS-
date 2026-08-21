import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/device_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. تهيئة بيئة الفلاتر
  WidgetsFlutterBinding.ensureInitialized();

  // 2. محاولة تشغيل الفايربيس مع حماية التطبيق من التجمد في حال فشل أو تأخر الاتصال
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint("⚠️ تجاوز الوقت المحد للاتصال بـ Firebase، سيتم فتح التطبيق وتأجيل الاتصال.");
        return Firebase.app();
      },
    );
    debugPrint("✅ تم الاتصال بـ Firebase بنجاح!");
  } catch (e) {
    debugPrint("⚠️ تعذر الاتصال بـ Firebase: $e");
  }

  // 3. فتح الشاشة الرئيسية فوراً
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        supportedLocales: const [Locale('ar', '')],
        locale: const Locale('ar', ''),
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
