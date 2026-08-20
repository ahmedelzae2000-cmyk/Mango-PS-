import 'package:flutter/material.dart';

class ShiftScreen extends StatelessWidget {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الوردية'),
      ),
      body: const Center(
        child: Text('شاشة إدارة الوردية'),
      ),
    );
  }
}
