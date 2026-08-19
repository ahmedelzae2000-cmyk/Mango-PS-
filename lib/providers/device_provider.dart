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

  // إضافة دالة addDevice بالوسائط التي تتوقعها الشاشات
  Future<void> addDevice(String name, String type, {double singleRate = 20.0, double multiRate = 30.0}) async {
    try {
      final docRef = await FirebaseFirestore.instance.collection('devices').add({
        'name': name,
        'type': type,
        'singleRate': singleRate,
        'multiRate': multiRate,
        'isOccupied': false,
        'mode': 'single',
        'paymentMethod': 'cash',
        'startTime': null,
      });

      _devices.add(DeviceModel(
        id: docRef.id,
        name: name,
        type: type,
        singleRate: singleRate,
        multiRate: multiRate,
      ));

      notifyListeners();
    } catch (e) {
      debugPrint("Error adding device: $e");
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
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      final now = DateTime.now();
      _devices[index].isOccupied = true;
      _devices[index].mode = mode;
      _devices[index].paymentMethod = payment;
      _devices[index].startTime = now;

      notifyListeners();

      await FirebaseFirestore.instance.collection('devices').doc(deviceId).update({
        'isOccupied': true,
        'mode': mode == GameMode.single ? 'single' : 'multi',
        'paymentMethod': payment.name,
        'startTime': Timestamp.fromDate(now),
      });
    }
  }

  Future<void> endSession(DeviceModel device) async {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index].isOccupied = false;
      _devices[index].startTime = null;

      notifyListeners();

      await FirebaseFirestore.instance.collection('devices').doc(device.id).update({
        'isOccupied': false,
        'startTime': null,
      });
    }
  }

  Future<void> updateCustomAmount(String deviceId, double amount) async {
    // إمكانية حفظ أو تسجيل الحساب المخصص
  }
}
 
