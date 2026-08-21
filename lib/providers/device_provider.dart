import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id;
  String name;
  String type;
  bool isOccupied;
  String mode; // 'single' or 'multi'
  Timestamp? startTime;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
    this.mode = 'single',
    this.startTime,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      isOccupied: data['isOccupied'] ?? false,
      mode: data['mode'] ?? 'single',
      startTime: data['startTime'],
    );
  }
}

class DeviceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];

  List<DeviceModel> get devices => _devices;

  DeviceProvider() {
    _db.collection('devices').snapshots().listen((snapshot) {
      _devices = snapshot.docs.map((doc) => DeviceModel.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  // دالة الإنهاء (المصححة)
  Future<void> stopSession(String deviceId) async {
    try {
      await _db.collection('devices').doc(deviceId).update({
        'isOccupied': false,
        'startTime': null,
        'mode': 'single',
      });
    } catch (e) {
      debugPrint("خطأ في إنهاء الجلسة: $e");
    }
  }

  // دالة تغيير وضع اللعب
  Future<void> toggleMode(String deviceId, String currentMode) async {
    String newMode = currentMode == 'single' ? 'multi' : 'single';
    await _db.collection('devices').doc(deviceId).update({'mode': newMode});
  }
}
