import 'package:flutter/material.dart';
import '../models/device_model.dart';

class DeviceProvider extends ChangeNotifier {
  final List<Device> _devices = [
    Device(id: '1', name: 'جهاز 1 (PS5)', type: 'PS5', isOccupied: false),
    Device(id: '2', name: 'جهاز 2 (PS4)', type: 'PS4', isOccupied: false),
  ];

  List<Device> get devices => _devices;

  void loadDevices() {
    notifyListeners();
  }

  void addDevice(String name, String type) {
    final newDevice = Device(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      isOccupied: false,
    );
    _devices.add(newDevice);
    notifyListeners();
  }

  void toggleDeviceState(Device device) {
    device.isOccupied = !device.isOccupied;
    notifyListeners();
  }

  void startSession(String deviceId, GameMode mode, PaymentMethod payment) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index].isOccupied = true;
      notifyListeners();
    }
  }

  void endSession(Device device) {
    device.isOccupied = false;
    notifyListeners();
  }
}
