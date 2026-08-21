import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// موديل الجهاز
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

// البروفايدر
class DeviceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];

  // إعدادات التطبيق
  String _appMode = 'فاتح (Light)';
  String _backgroundType = 'افتراضي (Purple)';
  String? _customImagePath;

  String get appMode => _appMode;
  String get backgroundType => _backgroundType;
  String? get customImagePath => _customImagePath;

  List<DeviceModel> get devices => _devices;

  DeviceProvider() {
    _loadSettings();
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

  // تحميل الإعدادات المحفوظة
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _appMode = prefs.getString('app_mode') ?? 'فاتح (Light)';
    _backgroundType = prefs.getString('app_bg') ?? 'افتراضي (Purple)';
    _customImagePath = prefs.getString('custom_image_path');
    notifyListeners();
  }

  // تحديث وحفظ الإعدادات
  Future<void> updateSettings(String mode, String bgType, {String? imagePath}) async {
    _appMode = mode;
    _backgroundType = bgType;
    if (imagePath != null) {
      _customImagePath = imagePath;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode);
    await prefs.setString('app_bg', bgType);
    if (imagePath != null) {
      await prefs.setString('custom_image_path', imagePath);
    }
    
    notifyListeners();
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
    await _db.collection('devices').doc(deviceId).update({'mode': newMode});
  }

  Future<void> stopSession(String deviceId, String deviceName, String paymentMethod, double finalCost) async {
    final batch = _db.batch();

    final deviceRef = _db.collection('devices').doc(deviceId);
    batch.update(deviceRef, {
      'isOccupied': false,
      'startTime': null,
      'mode': 'single',
    });

    // تحديث الوردية النشطة
    final activeShiftQuery = await _db.collection('shifts')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    
    if (activeShiftQuery.docs.isNotEmpty) {
      final shiftDoc = activeShiftQuery.docs.first;
      final shiftRef = shiftDoc.reference;
      
      final data = shiftDoc.data();
      double currentTotal = (data['totalRevenue'] ?? 0.0).toDouble();
      double currentCash = (data['cashRevenue'] ?? 0.0).toDouble();
      double currentVisa = (data['visaRevenue'] ?? 0.0).toDouble();

      currentTotal += finalCost;
      if (paymentMethod == 'كاش') {
        currentCash += finalCost;
      } else {
        currentVisa += finalCost;
      }

      batch.update(shiftRef, {
        'totalRevenue': currentTotal,
        'cashRevenue': currentCash,
        'visaRevenue': currentVisa,
      });
    }

    await batch.commit();

    // حفظ تفاصيل الجلسة في سجل الورديات (History)
    await _db.collection('history').add({
      'deviceName': deviceName,
      'cost': finalCost,
      'paymentMethod': paymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }
}
