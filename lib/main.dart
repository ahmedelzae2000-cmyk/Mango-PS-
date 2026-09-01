import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/device_provider.dart';
import 'screens/home_screen.dart';
import 'screens/shift_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. تهيئة الفايربيز
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB5UujdLmnqFvmujV3FSwSH2iI0L-78jk4",
      appId: "1:603196411064:android:c0b7cd83ee50712d9ef84d",
      messagingSenderId: "603196411064",
      projectId: "mango-ps",
      storageBucket: "mango-ps.firebasestorage.app",
    ),
  );

  // 2. التحقق من حالة تسجيل الدخول المحفوظة
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: Consumer<DeviceProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Mango PS',
            debugShowCheckedModeBanner: false,
            themeMode: provider.appMode == 'داكن (Dark)' ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.deepPurple,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.darkTheme == null ? Colors.deepPurple : Colors.deepPurple,
              useMaterial3: true,
            ),
            // إذا كان مسجلاً للدخول ينتقل للرئيسية مباشرة، وإلا يفتح شاشة الدخول
            home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/shift': (context) => const ShiftScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/login': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
