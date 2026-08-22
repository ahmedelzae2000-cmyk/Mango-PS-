import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'shift_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DevicesPage(),
    const ShiftScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Manga PS (${provider.userRole})'),
        actions: [
          IconButton(
            icon: Icon(
              provider.userRole == 'مدير' ? Icons.lock_open : Icons.lock,
              color: provider.userRole == 'مدير' ? Colors.greenAccent : Colors.redAccent,
            ),
            tooltip: 'التحكم بالصلاحيات',
            onPressed: () {
              if (provider.userRole == 'مدير') {
                provider.setUserRole('موظف');
              } else {
                _showAdminLoginDialog(context);
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DevicesPage(),
          ShiftScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'الأجهزة'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'الورديات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دخول الإدارة'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'كلمة مرور المدير'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text == '1234') {
                Provider.of<DeviceProvider>(context, listen: false).setUserRole('مدير');
                Navigator.pop(ctx);
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: provider.devices.isEmpty
          ? const Center(child: Text('لا يوجد أجهزة'))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8),
              itemCount: provider.devices.length,
              itemBuilder: (context, index) => DeviceGridCard(device: provider.devices[index]),
            ),
      floatingActionButton: provider.userRole == 'مدير' 
          ? FloatingActionButton(onPressed: () => _showAddDeviceDialog(context), child: const Icon(Icons.add)) 
          : null,
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    // كود الإضافة كما هو عندك..
  }
}

class DeviceGridCard extends StatelessWidget {
  final DeviceModel device;
  const DeviceGridCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    // كود الكارت اللي بتعرض فيه اسم الجهاز والحالة..
    return Card(child: Center(child: Text(device.name)));
  }
}
 
