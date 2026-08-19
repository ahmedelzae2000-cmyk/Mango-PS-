import 'package:cloud_firestore/cloud_firestore.dart';

enum GameMode { single, multi }
enum PaymentMethod { cash, vodafoneCash, instapay }

class DeviceModel {
  final String id;
  final String name;
  final String type;
  final double singleRate;
  final double multiRate;
  bool isOccupied;
  GameMode mode;
  PaymentMethod paymentMethod;
  DateTime? startTime;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.singleRate,
    required this.multiRate,
    this.isOccupied = false,
    this.mode = GameMode.single,
    this.paymentMethod = PaymentMethod.cash,
    this.startTime,
  });

  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DeviceModel(
      id: doc.id,
      name: data['name'] ?? 'جهاز',
      type: data['type'] ?? 'PS4',
      singleRate: (data['singleRate'] ?? 0).toDouble(),
      multiRate: (data['multiRate'] ?? 0).toDouble(),
      isOccupied: data['isOccupied'] ?? false,
      mode: data['mode'] == 'multi' ? GameMode.multi : GameMode.single,
      paymentMethod: _parsePayment(data['paymentMethod']),
      startTime: data['startTime'] != null 
          ? (data['startTime'] as Timestamp).toDate() 
          : null,
    );
  }

  static PaymentMethod _parsePayment(String? method) {
    switch (method) {
      case 'vodafoneCash': return PaymentMethod.vodafoneCash;
      case 'instapay': return PaymentMethod.instapay;
      default: return PaymentMethod.cash;
    }
  }
}
