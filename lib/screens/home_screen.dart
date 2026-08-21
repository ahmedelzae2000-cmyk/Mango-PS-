import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeviceProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('الأجهزة')),
      body: ListView.builder(
        itemCount: provider.devices.length,
        itemBuilder: (context, index) {
          final device = provider.devices[index];
          return ListTile(
            title: Text(device.name),
            trailing: device.isOccupied 
              ? ElevatedButton(
                  onPressed: () => provider.stopSession(device.id),
                  child: const Text('إنهاء وحساب'),
                )
              : const Text('متاح'),
          );
        },
      ),
    );
  }
}
 
