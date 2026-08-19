import 'package:flutter/material.dart';

enum UserRole { admin, staff, employee }

class AuthProvider extends ChangeNotifier {
  UserRole _role = UserRole.admin;
  UserRole get role => _role;

  Future<bool> login(UserRole role, String password) async {
    // التحقق من كلمة السر بناءً على الدور المختار
    if (role == UserRole.admin && password == '123456') {
      _role = UserRole.admin;
      notifyListeners();
      return true;
    } else if ((role == UserRole.staff || role == UserRole.employee) && password == '123') {
      _role = UserRole.staff;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    notifyListeners();
  }
}
