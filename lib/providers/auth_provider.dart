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

  // التحقق من الرقم السري وتسجيل الدخول
  Future<bool> login(String password, UserRole role) async {
    try {
      final docKey = role == UserRole.admin ? 'admin_pass' : 'staff_pass';
      final doc = await _firestore.collection('settings').doc('auth').get();

      String correctPassword;
      if (doc.exists && doc.data()!.containsKey(docKey)) {
        correctPassword = doc.data()![docKey];
      } else {
        // كلمات السر الافتراضية في أول مرة تشغيل
        correctPassword = role == UserRole.admin ? '123456' : '112233';
        await _firestore.collection('settings').doc('auth').set({
          docKey: correctPassword,
        }, SetOptions(merge: true));
      }

      if (password == correctPassword) {
        _currentRole = role;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول: $e');
      return false;
    }
  }

  // تغيير باسورد صاحب المحل أو الموظفين (لصاحب المحل فقط)
  Future<bool> updatePassword(UserRole roleToUpdate, String newPassword) async {
    if (!isAdmin) return false;
    try {
      final docKey = roleToUpdate == UserRole.admin ? 'admin_pass' : 'staff_pass';
      await _firestore.collection('settings').doc('auth').set({
        docKey: newPassword,
      }, SetOptions(merge: true));
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
