import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/auth_provider.dart';
import 'pricing_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DeviceProvider>(context, listen: false).loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS - الشاشة الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                authProvider.role == UserRole.admin ? 'حساب: صاحب المحل' : 'حساب: موظف',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text('Manga PS System'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.sports_esports, color: Color(0xFF1E88E5), size: 36),
              ),
            ),
            if (authProvider.role == UserRole.admin)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('تعديل الأسعار وإضافة أجهزة'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PricingScreen()),
                  );
                },
              ),
          ],
        ),
      ),
      body: deviceProvider.devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.devices, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لا يوجد أجهزة مضافة حتى الآن',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  if (authProvider.role == UserRole.admin)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PricingScreen()),
                        );
                      },
                      child: const Text('إضافة أجهزة جديدة'),
                    ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: deviceProvider.devices.length,
              itemBuilder: (context, index) {
                final device = deviceProvider.devices[index];
                return Card(
                  color: device.isOccupied ? Colors.red.shade900 : Colors.green.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'النوع: ${device.type}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          device.isOccupied ? 'مشغول' : 'متاح',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (device.isOccupied) {
                              deviceProvider.endSession(device);
                            } else {
                              deviceProvider.startSession(
                                device.id,
                                GameMode.single,
                                PaymentMethod.cash,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: device.isOccupied ? Colors.orange : Colors.blue,
                          ),
                          child: Text(device.isOccupied ? 'إنهاء الجلسة' : 'بدء جلسة'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
 
