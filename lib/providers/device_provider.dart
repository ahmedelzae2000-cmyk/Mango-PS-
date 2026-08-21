import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id;
  String name;
  String type; // PS4 or PS5
  bool isOccupied;
  String mode; // 'single' or 'multi'
  Timestamp? startTime;
  double pricePerHour;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
    this.mode = 'single',
    this.startTime,
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
          pricePerHour: (data['pricePerHour'] ?? 30.0).toDouble(),
        );
      }).toList();
      notifyListeners();
    });
  }

  // 1. إضافة جهاز جديد (PS4 / PS5)
  Future<void> addDevice(String name, String type, double price) async {
    await _db.collection('devices').add({
      'name': name,
      'type': type,
      'isOccupied': false,
      'mode': 'single',
      'startTime': null,
      'pricePerHour': price,
    });
  }

  // 2. بدء الجلسة (اختيار سنجل أو ملتي)
  Future<void> startSession(String deviceId, String mode) async {
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': true,
      'mode': mode,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // 3. تعديل سعر الجهاز
  Future<void> updatePrice(String deviceId, double newPrice) async {
    await _db.collection('devices').doc(deviceId).update({
      'pricePerHour': newPrice,
    });
  }

  // 4. إنهاء الجلسة وحساب الوقت
  Future<void> stopSession(String deviceId) async {
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': false,
      'startTime': null,
    });
  }
}
