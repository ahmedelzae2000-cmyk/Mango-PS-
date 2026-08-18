import 'package:cloud_firestore/cloud_firestore.dart';

enum GameMode { single, multi }
enum PaymentMethod { cash, vodafoneCash, instapay }

class DeviceModel {
  final String id;
  final String name; // مثل: PS4 - 1
  final String type; // PS4 أو PS5
  bool isOccupied;
  GameMode mode;
  PaymentMethod paymentMethod;
  DateTime? startTime;
  double customTotalAmount; // لتعديل الحساب قبل إنهاء الجلسة إن وجد

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
    this.mode = GameMode.single,
    this.paymentMethod = PaymentMethod.cash,
    this.startTime,
    this.customTotalAmount = 0.0,
  });

  // تحويل البيانات لـ Map لرفعها لـ Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isOccupied': isOccupied,
      'mode': mode.name,
      'paymentMethod': paymentMethod.name,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'customTotalAmount': customTotalAmount,
    };
  }

  // قراءة البيانات من Firestore
  factory DeviceModel.fromMap(Map<String, dynamic> map, String docId) {
    return DeviceModel(
      id: docId,
      name: map['name'] ?? '',
      type: map['type'] ?? 'PS4',
      isOccupied: map['isOccupied'] ?? false,
      mode: GameMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => GameMode.single,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      customTotalAmount: (map['customTotalAmount'] ?? 0.0).toDouble(),
    );
  }
}
