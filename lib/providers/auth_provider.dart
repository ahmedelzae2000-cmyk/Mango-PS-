import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, staff }

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  UserRole? _currentRole;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  UserRole? get currentRole => _currentRole;
  bool get isAdmin => _currentRole == UserRole.admin;

  Future<bool> login(String password, UserRole role) async {
    _isLoading = true;
    notifyListeners();

    // تنظيف الباسورد المدخل من أي مسافات زائدة في البداية أو النهاية
    final cleanInput = password.trim();

    try {
      // تجربة جلب البيانات الحديثة مباشرة من السيرفر أولاً
      final docSnap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('auth')
          .get(const GetOptions(source: Source.server));

      final targetField = role == UserRole.admin ? 'admin_pass' : 'staff_pass';

      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final correctPass = data[targetField]?.toString().trim();

        if (correctPass != null && correctPass == cleanInput) {
          _isLoggedIn = true;
          _currentRole = role;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Firestore Auth Server Fetch Error: $e");
    }

    // fallback: فحص الباسوردات الافتراضية
    final defaultPass = role == UserRole.admin ? '123456' : '112233';
    if (cleanInput == defaultPass) {
      _isLoggedIn = true;
      _currentRole = role;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _currentRole = null;
    notifyListeners();
  }
}
