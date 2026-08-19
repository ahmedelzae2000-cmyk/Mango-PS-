import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_model.dart';

class DeviceProvider extends ChangeNotifier {
  List<DeviceModel> _devices = [];
  List<DeviceModel> get devices => _devices;

  Future<void> loadDevices() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('devices').get();
      _devices = snap.docs.map((doc) => DeviceModel.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading devices: $e");
    }
  }

  double calculateCurrentCost(DeviceModel device) {
    if (!device.isOccupied || device.startTime == null) return 0.0;
    final now = DateTime.now();
    final durationInHours = now.difference(device.startTime!).inSeconds / 3600.0;
    final rate = device.mode == GameMode.single ? device.singleRate : device.multiRate;
    return durationInHours * rate;
  }

  Future<void> startSession(String deviceId, GameMode mode, PaymentMethod payment) async {
    // كود بدء الجلسة لديك
  }

  Future<void> endSession(DeviceModel device) async {
    // كود إنهاء الجلسة لديك
  }

  Future<void> updateCustomAmount(String deviceId, double amount) async {
    // كود تعديل الحساب لديك
  }
}
