import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import 'pricing_screen.dart';
import 'expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // استقبال الـ Provider بآمان مع حماية من الأخطاء
    final deviceProvider = Provider.of<DeviceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS - إدارة الصالة'),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Manga PS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              accountEmail: Text('نظام إدارة صالة الألعاب'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.sports_esports, color: Colors.blue, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.tv),
              title: const Text('شاشة الأجهزة'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('المصاريف'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('إدارة الأجهزة والأسعار'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('إضافة جهاز'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
        },
      ),
      body: deviceProvider.devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.devices_other, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أجهزة مضافة حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة جهاز يدوي'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
                    },
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: deviceProvider.devices.length,
              itemBuilder: (context, index) {
                final device = deviceProvider.devices[index];
                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('النوع: ${device.type}'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: device.isOccupied ? Colors.red.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            device.isOccupied ? 'مشغول' : 'متاح',
                            style: TextStyle(
                              color: device.isOccupied ? Colors.red.shade900 : Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: device.isOccupied ? Colors.red : Colors.green,
                            ),
                            onPressed: () {
                              deviceProvider.toggleDeviceState(device);
                            },
                            child: Text(
                              device.isOccupied ? 'إنهاء' : 'بدء',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
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
