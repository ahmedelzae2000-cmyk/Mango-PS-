import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, staff }

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> login(String password, UserRole role) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. القراءة مباشرة من مجموعة settings ومستند auth
      final docSnap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('auth')
          .get(const GetOptions(source: Source.serverAndCache));

      final targetField = role == UserRole.admin ? 'admin_pass' : 'staff_pass';

      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        final correctPass = data[targetField]?.toString();

        if (correctPass != null && correctPass == password) {
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // 2. فحص احتياطي للباسوردات الافتراضية
      final defaultPass = role == UserRole.admin ? '123456' : '112233';
      if (password == defaultPass) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Firestore Auth Error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
