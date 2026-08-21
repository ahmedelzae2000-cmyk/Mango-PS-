import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id;
  String name;
  String type;
  bool isOccupied;
  String mode;
  Timestamp? startTime;
  double singlePrice;
  double multiPrice;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
    this.mode = 'single',
    this.startTime,
    required this.singlePrice,
    required this.multiPrice,
  });
}

class DeviceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];

  List<DeviceModel> get devices => _devices;

  DeviceProvider() {
    _db.collection('devices').snapshots().listen((snapshot) {
      _devices = snapshot.docs.map((doc) {
        var data = doc.data();
        return DeviceModel(
          id: doc.id,
          name: data['name'] ?? '',
          type: data['type'] ?? 'PS4',
          isOccupied: data['isOccupied'] ?? false,
          mode: data['mode'] ?? 'single',
          startTime: data['startTime'],
          singlePrice: (data['singlePrice'] ?? 30.0).toDouble(),
          multiPrice: (data['multiPrice'] ?? 40.0).toDouble(),
        );
      }).toList();
      notifyListeners();
    });
  }

  Future<void> addDevice(String name, String type, double singlePrice, double multiPrice) async {
    await _db.collection('devices').add({
      'name': name,
      'type': type,
      'isOccupied': false,
      'mode': 'single',
      'startTime': null,
      'singlePrice': singlePrice,
      'multiPrice': multiPrice,
    });
  }

  Future<void> startSession(String deviceId, String mode) async {
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': true,
      'mode': mode,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleMode(String deviceId, String currentMode) async {
    String newMode = currentMode == 'single' ? 'multi' : 'single';
    await _db.collection('devices').doc(deviceId).update({
      'mode': newMode,
    });
  }

  // إنهاء الجلسة مع إمكانية حفظ التكلفة النهائية وطريقة الدفع
  Future<void> stopSession(String deviceId, String paymentMethod, double finalCost) async {
    // يمكنك هنا لاحقاً حفظ الـ finalCost وطريقة الدفع في جدول الإيرادات/التقارير
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': false,
      'startTime': null,
      'mode': 'single',
    });
  }
}
