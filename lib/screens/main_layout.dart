import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';
import 'shift_screen.dart';
import 'expenses_screen.dart';
import 'pricing_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // القائمة الكاملة للشاشات الـ 7
  final List<Widget> _screens = [
    const HomeScreen(),
    const ShiftScreen(),
    const ExpensesScreen(),
    const Center(child: Text('شاشة البوفيه والمشروبات', style: TextStyle(fontSize: 20))), // شاشة البوفيه
    const PricingScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        currentScreenIndex: _currentIndex,
        onSelectScreen: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: _screens[_currentIndex],
    );
  }
}
