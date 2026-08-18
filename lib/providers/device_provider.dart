import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_model.dart';
import '../models/pricing_model.dart';

class DeviceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];
  PricingModel _pricing = PricingModel();

  List<DeviceModel> get devices => _devices;
  PricingModel get pricing => _pricing;

  DeviceProvider() {
    listenToDevices();
    listenToPricing();
  }

  // الاستماع لتغيرات الأجهزة أونلاين وأوفلاين
  void listenToDevices() {
    _firestore.collection('devices').snapshots().listen((snapshot) {
      _devices = snapshot.docs
          .map((doc) => DeviceModel.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    });
  }

  // الاستماع للأسعار
  void listenToPricing() {
    _firestore.collection('settings').doc('pricing').snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        _pricing = PricingModel.fromMap(doc.data()!);
        notifyListeners();
      }
    });
  }

  // إضافة جهاز جديد (للأدمين)
  Future<void> addDevice(String name, String type) async {
    final docRef = _firestore.collection('devices').doc();
    final newDevice = DeviceModel(
      id: docRef.id,
      name: name,
      type: type,
    );
    await docRef.set(newDevice.toMap());
  }

  // بدء الجلسة
  Future<void> startSession(String deviceId, GameMode mode, PaymentMethod method) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'isOccupied': true,
      'startTime': Timestamp.now(),
      'mode': mode.name,
      'paymentMethod': method.name,
      'customTotalAmount': 0.0,
    });
  }

  // تغيير نوع اللعب أو طريقة الدفع أثناء الجلسة
  Future<void> updateSessionSettings(String deviceId, GameMode mode, PaymentMethod method) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'mode': mode.name,
      'paymentMethod': method.name,
    });
  }

  // تعديل المبلغ يدويًا قبل الإنهاء
  Future<void> updateCustomAmount(String deviceId, double amount) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'customTotalAmount': amount,
    });
  }

  // حساب التكلفة الحالية بناءً على الوقت المستغرق
  double calculateCurrentCost(DeviceModel device) {
    if (device.customTotalAmount > 0) return device.customTotalAmount;
    if (device.startTime == null) return 0.0;

    final duration = DateTime.now().difference(device.startTime!);
    final hours = duration.inMinutes / 60.0;

    double rate = 0.0;
    if (device.type == 'PS4') {
      rate = device.mode == GameMode.single ? _pricing.ps4SingleRate : _pricing.ps4MultiRate;
    } else {
      rate = device.mode == GameMode.single ? _pricing.ps5SingleRate : _pricing.ps5MultiRate;
    }

    return (hours * rate);
  }

  // إنهاء الجلسة وترحيل التكلفة للوردية
  Future<double> endSession(DeviceModel device) async {
    final finalCost = calculateCurrentCost(device);
    
    // تسجيل الجلسة في سجل الجلسات
    await _firestore.collection('sessions').add({
      'deviceId': device.id,
      'deviceName': device.name,
      'deviceType': device.type,
      'mode': device.mode.name,
      'paymentMethod': device.paymentMethod.name,
      'startTime': Timestamp.fromDate(device.startTime!),
      'endTime': Timestamp.now(),
      'totalCost': finalCost,
    });

    // إعادة ضبط الجهاز
    await _firestore.collection('devices').doc(device.id).update({
      'isOccupied': false,
      'startTime': null,
      'customTotalAmount': 0.0,
    });

    return finalCost;
  }

  // تحديث قائمة الأسعار (صاحب المحل)
  Future<void> updatePricing(PricingModel newPricing) async {
    await _firestore.collection('settings').doc('pricing').set(newPricing.toMap());
  }
}
