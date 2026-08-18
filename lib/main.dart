import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تفعيل التخزين المحلي للأوفلاين تلقائياً
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MangaPsApp());
}

class MangaPsApp extends StatelessWidget {
  const MangaPsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      
      // إعدادات اللغة العربية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
      ],
      locale: const Locale('ar', 'EG'),

      // الثيم الداكن المخصص (Dark Mode)
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF1E88E5),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF00E676), // للنجاح/بدء الجلسة
          error: Color(0xFFFF5252),     // للإيقاف/المصاريف
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1F1F1F),
          elevation: 2,
          centerTitle: true,
          titleTextStyle: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Manga PS - أهلاً بك في النظام',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
 
