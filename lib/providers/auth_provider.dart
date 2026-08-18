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
      
      // إضافة timeout لمنع التعليق اللانهائي
      final doc = await _firestore
          .collection('settings')
          .doc('auth')
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout connection to Firestore');
        },
      );

      String correctPassword;
      if (doc.exists && doc.data() != null && doc.data()!.containsKey(docKey)) {
        correctPassword = doc.data()![docKey];
      } else {
        // كلمات السر الافتراضية في أول مرة تشغيل
        correctPassword = role == UserRole.admin ? '123456' : '112233';
        
        // محاولة حفظ الكلمة الافتراضية بدون تعطيل العملية الرئيسية
        _firestore.collection('settings').doc('auth').set({
          docKey: correctPassword,
        }, SetOptions(merge: true)).catchError((e) => debugPrint('Error saving default pass: $e'));
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
      
      // تجربة الدخول برقم السر الافتراضي إذا فشل الفايربيس
      final defaultPass = role == UserRole.admin ? '123456' : '112233';
      if (password == defaultPass) {
        _currentRole = role;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
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
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
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
 
