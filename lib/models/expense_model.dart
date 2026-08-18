import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount; // بالجنيه المصري
  final DateTime dateTime;
  final String addedBy; // اسم الموظف أو صاحب المحل

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dateTime,
    required this.addedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dateTime': Timestamp.fromDate(dateTime),
      'addedBy': addedBy,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExpenseModel(
      id: docId,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dateTime: map['dateTime'] != null
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      addedBy: map['addedBy'] ?? 'موظف',
    );
  }
}
