import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id;
  String name;
  String type;
  bool isOccupied;
  String isMulti; // 'single' أو 'multi'
  DateTime? startTime;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
    this.isMulti = 'single',
    this.startTime,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      isOccupied: data['isOccupied'] ?? false,
      isMulti: data['isMulti'] ?? 'single',
      startTime: data['startTime'] != null 
          ? (data['startTime'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isOccupied': isOccupied,
      'isMulti': isMulti,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
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
      'isMulti': 'single',
      'startTime': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // بدء جلسه جديدة للجهاز
  Future<void> startSession(String deviceId, String mode) async {
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': true,
      'isMulti': mode,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // تبديل وضع اللعب (سنجل / ملتي)
  Future<void> togglePlayMode(DeviceModel device) async {
    String newMode = device.isMulti == 'single' ? 'multi' : 'single';
    await _db.collection('devices').doc(device.id).update({
      'isMulti': newMode,
    });
  }

  // إنهاء الجلسة وإعادة الجهاز للحالة المتاحة
  Future<void> stopSession(String deviceId) async {
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': false,
      'startTime': null,
      'isMulti': 'single',
    });
  }
}
