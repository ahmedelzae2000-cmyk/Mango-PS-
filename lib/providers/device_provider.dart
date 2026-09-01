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
  bool isPaused;              // حالة الإيقاف المؤقت
  int pausedDuration;         // إجمالي ثواني الإيقاف
  Timestamp? pauseStartTime;  // وقت بدء الإيقاف الحالي

  DeviceModel({
    required this.id, 
    required this.name, 
    required this.type, 
    this.isOccupied = false, 
    this.mode = 'single', 
    this.startTime, 
    required this.singlePrice, 
    required this.multiPrice,
    this.isPaused = false,
    this.pausedDuration = 0,
    this.pauseStartTime,
  });
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
          isPaused: data['isPaused'] ?? false,
          pausedDuration: data['pausedDuration'] ?? 0,
          pauseStartTime: data['pauseStartTime'],
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

  Future<void> deleteExpenseOrAdvance(String id) async {
    if (_userRole != 'مدير') return;
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

  Future<void> setUserRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    notifyListeners();
  }

  // --- دوال الأجهزة والورديات والجلسات ---

  Future<void> addDevice(String name, String type, double s, double m) async {
    if (_userRole != 'مدير') return;
    await _db.collection('devices').add({
      'name': name, 
      'type': type, 
      'isOccupied': false, 
      'mode': 'single', 
      'singlePrice': s, 
      'multiPrice': m,
      'isPaused': false,
      'pausedDuration': 0,
      'pauseStartTime': null,
    });
  }

  Future<void> deleteDevice(String id) async {
    if (_userRole != 'مدير') return;
    await _db.collection('devices').doc(id).delete();
  }

  Future<void> clearHistoryAndShifts() async {
    if (_userRole != 'مدير') return;

    var shifts = await _db.collection('shifts').get();
    for (var doc in shifts.docs) {
      await doc.reference.delete();
    }

    var history = await _db.collection('history').get();
    for (var doc in history.docs) {
      await doc.reference.delete();
    }
    notifyListeners();
  }

  Future<bool> _hasActiveShift() async {
    final activeShiftQuery = await _db.collection('shifts')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return activeShiftQuery.docs.isNotEmpty;
  }

  Future<bool> startSession(String id, String mode) async {
    bool shiftActive = await _hasActiveShift();
    if (!shiftActive) return false;

    await _db.collection('devices').doc(id).update({
      'isOccupied': true, 
      'mode': mode, 
      'startTime': FieldValue.serverTimestamp(),
      'isPaused': false,
      'pausedDuration': 0,
      'pauseStartTime': null,
    });
    return true;
  }

  Future<void> toggleMode(String id, String mode) async {
    await _db.collection('devices').doc(id).update({'mode': mode});
  }

  // --- دالة الإيقاف المؤقت / الاستئناف ---
  Future<void> togglePauseSession(String id, bool currentPausedState) async {
    var deviceDoc = await _db.collection('devices').doc(id).get();
    if (!deviceDoc.exists) return;

    var data = deviceDoc.data() as Map<String, dynamic>;

    if (!currentPausedState) {
      // الانتقال إلى وضع "الإيقاف المؤقت"
      await _db.collection('devices').doc(id).update({
        'isPaused': true,
        'pauseStartTime': FieldValue.serverTimestamp(),
      });
    } else {
      // العودة إلى وضع "الاستئناف وتشغيل العداد"
      Timestamp? pauseStart = data['pauseStartTime'];
      int currentPausedDuration = data['pausedDuration'] ?? 0;

      if (pauseStart != null) {
        int additionalPausedSeconds = DateTime.now().difference(pauseStart.toDate()).inSeconds;
        currentPausedDuration += additionalPausedSeconds;
      }

      await _db.collection('devices').doc(id).update({
        'isPaused': false,
        'pausedDuration': currentPausedDuration,
        'pauseStartTime': null,
      });
    }
  }

  Future<void> stopSession(String id, String name, String method, double cost) async {
    final activeShiftQuery = await _db.collection('shifts').where('isActive', isEqualTo: true).limit(1).get();
    if (activeShiftQuery.docs.isEmpty) return;

    final batch = _db.batch();
    
    // 1. إيقاف الجهاز وتصفير الإيقاف المؤقت وإرجاعه للحالة العادية
    batch.update(_db.collection('devices').doc(id), {
      'isOccupied': false, 
      'startTime': null, 
      'mode': 'single',
      'isPaused': false,
      'pausedDuration': 0,
      'pauseStartTime': null,
    });

    // 2. تحديث إيرادات الوردية النشطة
    final doc = activeShiftQuery.docs.first;
    String currentShiftId = doc.id;
    
    String revenueField = method == 'كاش' ? 'cashRevenue' : 'visaRevenue';
    double currentTotal = (doc.data()['totalRevenue'] ?? 0.0).toDouble();
    double currentMethodRevenue = (doc.data()[revenueField] ?? 0.0).toDouble();

    batch.update(doc.reference, {
      'totalRevenue': currentTotal + cost,
      revenueField: currentMethodRevenue + cost,
    });

    // 3. تسجيل تفاصيل الجلسة في كولكشن history
    DocumentReference historyRef = _db.collection('history').doc();
    batch.set(historyRef, {
      'deviceName': name,
      'cost': cost,
      'paymentMethod': method,
      'timestamp': FieldValue.serverTimestamp(),
      'shiftId': currentShiftId,
      'closedBy': _userRole,
    });

    await batch.commit();
  }

  // --- دالة تعديل قيمة الفاتورة ومزامنتها مع الوردية والتقارير ---
  Future<void> updateShiftSessionAmount({
    required String historyId,
    required double newAmount,
    required double oldAmount,
    required String paymentMethod,
  }) async {
    if (_userRole != 'مدير') return;

    double diff = newAmount - oldAmount;

    // 1. تحديث قيمة الفاتورة في كولكشن السجل history
    await _db.collection('history').doc(historyId).update({'cost': newAmount});

    // 2. تحديث الوردية النشطة بالفرق المالي
    var activeShiftQuery = await _db.collection('shifts').where('isActive', isEqualTo: true).limit(1).get();
    if (activeShiftQuery.docs.isNotEmpty) {
      var shiftDoc = activeShiftQuery.docs.first;
      var shiftData = shiftDoc.data();

      double currentTotal = (shiftData['totalRevenue'] ?? 0.0).toDouble();
      double currentCash = (shiftData['cashRevenue'] ?? 0.0).toDouble();
      double currentVisa = (shiftData['visaRevenue'] ?? 0.0).toDouble();

      if (paymentMethod == 'كاش') {
        currentCash += diff;
      } else {
        currentVisa += diff;
      }

      await _db.collection('shifts').doc(shiftDoc.id).update({
        'totalRevenue': currentTotal + diff < 0 ? 0.0 : currentTotal + diff,
        'cashRevenue': currentCash < 0 ? 0.0 : currentCash,
        'visaRevenue': currentVisa < 0 ? 0.0 : currentVisa,
      });
    }

    notifyListeners();
  }
  
  // دالة لحساب إجمالي المبيعات للوردية الحالية
  double getCurrentShiftTotalSales() {
    return _devices.fold(0.0, (sum, device) => sum); 
  }
}
