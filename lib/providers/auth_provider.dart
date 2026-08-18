import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, staff }

class AuthProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserRole? _currentRole;
  bool _isLoggedIn = false;

  UserRole? get currentRole => _currentRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _currentRole == UserRole.admin;

  Future<bool> login(String password, UserRole role) async {
    final defaultPass = role == UserRole.admin ? '123456' : '112233';

    try {
      final docKey = role == UserRole.admin ? 'admin_pass' : 'staff_pass';

      // المهلة 4 ثواني فقط لتجنب التحميل اللانهائي
      final doc = await _firestore
          .collection('settings')
          .doc('auth')
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null && doc.data()!.containsKey(docKey)) {
        final correctPassword = doc.data()![docKey];
        if (password == correctPassword) {
          _currentRole = role;
          _isLoggedIn = true;
          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('Firestore Error/Timeout: $e');
    }

    // الاعتماد على الرقم السري الافتراضي مباشرة عند حدوث مشكلة شبكة
    if (password == defaultPass) {
      _currentRole = role;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> updatePassword(UserRole roleToUpdate, String newPassword) async {
    if (!isAdmin) return false;
    try {
      final docKey = roleToUpdate == UserRole.admin ? 'admin_pass' : 'staff_pass';
      await _firestore.collection('settings').doc('auth').set({
        docKey: newPassword,
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _currentRole = null;
    notifyListeners();
  }
}
