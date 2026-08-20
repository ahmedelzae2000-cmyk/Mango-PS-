import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id;
  String name;
  String type;
  bool isOccupied;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      isOccupied: data['isOccupied'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isOccupied': isOccupied,
    };
  }
}

class DeviceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];

  List<DeviceModel> get devices => _devices;

  DeviceProvider() {
    fetchDevices();
  }

  // جلب الأجهزة لحظياً من Firestore
  void fetchDevices() {
    _db.collection('devices').snapshots().listen((snapshot) {
      _devices = snapshot.docs.map((doc) => DeviceModel.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  // إضافة جهاز جديد
  Future<void> addDevice(String name, String type) async {
    await _db.collection('devices').add({
      'name': name,
      'type': type,
      'isOccupied': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // تغيير حالة الجهاز (تشغيل / إنهاء)
  Future<void> toggleDeviceState(DeviceModel device) async {
    await _db.collection('devices').doc(device.id).update({
      'isOccupied': !device.isOccupied,
    });
  }
}
