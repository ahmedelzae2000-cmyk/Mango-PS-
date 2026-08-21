import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  String id;
  String name;
  bool isOccupied;

  DeviceModel({required this.id, required this.name, this.isOccupied = false});
}

class DeviceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];

  List<DeviceModel> get devices => _devices;

  DeviceProvider() {
    _db.collection('devices').snapshots().listen((snapshot) {
      _devices = snapshot.docs.map((doc) {
        return DeviceModel(
          id: doc.id,
          name: doc['name'] ?? '',
          isOccupied: doc['isOccupied'] ?? false,
        );
      }).toList();
      notifyListeners();
    });
  }

  // هذه دالة الإنهاء التي تحتاجها
  Future<void> stopSession(String deviceId) async {
    await _db.collection('devices').doc(deviceId).update({
      'isOccupied': false,
    });
  }
}
