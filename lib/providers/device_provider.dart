import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id, name, type, mode;
  bool isOccupied;
  Timestamp? startTime;
  double pricePerHour; // السعر الحالي للجهاز

  DeviceModel({
    required this.id, required this.name, required this.type,
    this.isOccupied = false, this.mode = 'single', this.startTime,
    this.pricePerHour = 30.0,
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
          pricePerHour: (data['price'] ?? 30.0).toDouble(),
        );
      }).toList();
      notifyListeners();
    });
  }

  // 1. إضافة جهاز جديد (PS4/PS5)
  Future<void> addDevice(String name, String type, double price) async {
    await _db.collection('devices').add({
      'name': name, 'type': type, 'price': price,
      'isOccupied': false, 'mode': 'single', 'startTime': null,
    });
  }

  // 2. بدء الجلسة (اختيار سنجل أو ملتي)
  Future<void> startSession(String id, String mode) async {
    await _db.collection('devices').doc(id).update({
      'isOccupied': true, 'mode': mode, 'startTime': FieldValue.serverTimestamp(),
    });
  }

  // 3. تعديل السعر قبل الإنهاء
  Future<void> updatePrice(String id, double newPrice) async {
    await _db.collection('devices').doc(id).update({'price': newPrice});
  }

  // 4. إنهاء الجلسة
  Future<void> stopSession(String id) async {
    await _db.collection('devices').doc(id).update({
      'isOccupied': false, 'startTime': null,
    });
  }
}
