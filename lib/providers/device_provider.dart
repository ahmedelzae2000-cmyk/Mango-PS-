import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// الموديلات
class DeviceModel {
  String id;
  String name;
  String type; 
  bool isOccupied;
  String mode; 
  Timestamp? startTime;
  double singlePrice;
  double multiPrice;

  DeviceModel({required this.id, required this.name, required this.type, this.isOccupied = false, this.mode = 'single', this.startTime, required this.singlePrice, required this.multiPrice});
}

class ExpenseModel {
  String id;
  String title;
  double amount;
  String type; // 'مصروف' أو 'سلفة'
  Timestamp? date;
  String shiftId;

  ExpenseModel({required this.id, required this.title, required this.amount, required this.type, this.date, required this.shiftId});
}

class DeviceProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<DeviceModel> _devices = [];
  List<ExpenseModel> _expenses = [];

  String _appMode = 'فاتح';
  String _backgroundType = 'افتراضي (بنفسجي)';
  String? _customImagePath;
  
  // صلاحية المستخدم الحالية (افتراضياً موظف)
  String _userRole = 'موظف';

  String get appMode => _appMode;
  String get backgroundType => _backgroundType;
  String? get customImagePath => _customImagePath;
  String get userRole => _userRole;
  List<DeviceModel> get devices => _devices;
  List<ExpenseModel> get expenses => _expenses;

  DeviceProvider() {
    _loadSettings();
    _initDeviceListener();
    _initExpenseListener();
  }

  void _initDeviceListener() {
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

  void _initExpenseListener() {
    _db.collection('expenses').snapshots().listen((snapshot) {
      _expenses = snapshot.docs.map((doc) {
        var data = doc.data();
        return ExpenseModel(
          id: doc.id,
          title: data['title'] ?? '',
          amount: (data['amount'] ?? 0.0).toDouble(),
          type: data['type'] ?? 'مصروف',
          date: data['date'],
          shiftId: data['shiftId'] ?? '',
        );
      }).toList();
      notifyListeners();
    });
  }

  // --- دوال المصاريف والسلف ---

  Future<void> addExpenseOrAdvance(String title, double amount, String type) async {
    // التأكد أن المستخدم مدير قبل إضافة مصروف أو سلفة
    if (_userRole != 'مدير') return;

    final activeShiftQuery = await _db.collection('shifts')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (activeShiftQuery.docs.isEmpty) return;

    await _db.collection('expenses').add({
      'title': title,
      'amount': amount,
      'type': type,
      'date': FieldValue.serverTimestamp(),
      'shiftId': activeShiftQuery.docs.first.id,
    });
  }

  // دالة حذف مصروف أو سلفة من قاعدة البيانات
  Future<void> deleteExpenseOrAdvance(String id) async {
    if (_userRole != 'مدير') return; // حماية إضافية للحذف
    await _db.collection('expenses').doc(id).delete();
  }

  double getExpensesTotalByType(String type) {
    return _expenses
        .where((e) => e.type == type)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // --- دوال الإعدادات وصلاحيات المستخدم ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _appMode = prefs.getString('app_mode') ?? 'فاتح';
    _backgroundType = prefs.getString('app_bg') ?? 'افتراضي (بنفسجي)';
    _customImagePath = prefs.getString('custom_image_path');
    _userRole = prefs.getString('user_role') ?? 'موظف';
    notifyListeners();
  }

  Future<void> updateSettings(String mode, String bgType, {String? imagePath}) async {
    _appMode = mode;
    _backgroundType = bgType;
    if (imagePath != null) _customImagePath = imagePath;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_mode', mode);
    await prefs.setString('app_bg', bgType);
    if (imagePath != null) await prefs.setString('custom_image_path', imagePath);
    notifyListeners();
  }

  // دالة لتغيير وحفظ دور المستخدم (مدير / موظف)
  Future<void> setUserRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    notifyListeners();
  }

  // --- دوال الأجهزة والورديات ---

  Future<void> addDevice(String name, String type, double s, double m) async {
    await _db.collection('devices').add({'name': name, 'type': type, 'isOccupied': false, 'mode': 'single', 'singlePrice': s, 'multiPrice': m});
  }

  Future<void> startSession(String id, String mode) async {
    await _db.collection('devices').doc(id).update({'isOccupied': true, 'mode': mode, 'startTime': FieldValue.serverTimestamp()});
  }

  Future<void> toggleMode(String id, String mode) async {
    await _db.collection('devices').doc(id).update({'mode': mode == 'single' ? 'multi' : 'single'});
  }

  Future<void> stopSession(String id, String name, String method, double cost) async {
    final batch = _db.batch();
    batch.update(_db.collection('devices').doc(id), {'isOccupied': false, 'startTime': null, 'mode': 'single'});

    final activeShiftQuery = await _db.collection('shifts').where('isActive', isEqualTo: true).limit(1).get();
    if (activeShiftQuery.docs.isNotEmpty) {
      final doc = activeShiftQuery.docs.first;
      batch.update(doc.reference, {
        'totalRevenue': (doc.data()['totalRevenue'] ?? 0.0) + cost,
        method == 'كاش' ? 'cashRevenue' : 'visaRevenue': (doc.data()[method == 'كاش' ? 'cashRevenue' : 'visaRevenue'] ?? 0.0) + cost
      });
    }
    await batch.commit();
  }
  
  double getCurrentShiftTotalSales() {
    return 0.0; 
  }
}
