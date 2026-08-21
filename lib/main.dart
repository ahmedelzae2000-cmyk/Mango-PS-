import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/device_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB5UujdLmnqFvmujV3FSwSH2iI0L-78jk4",
      appId: "1:603196411064:android:c0b7cd83ee50712d9ef84d",
      messagingSenderId: "603196411064",
      projectId: "mango-ps",
      storageBucket: "mango-ps.firebasestorage.app",
    ),
  );
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
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(), // البداية من شاشة الأجهزة
      ),
    );
  }
}
 
