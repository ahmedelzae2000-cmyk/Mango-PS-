import 'package:flutter/material.dart';

enum UserRole { admin, employee }

class AuthProvider extends ChangeNotifier {
  UserRole _role = UserRole.admin;
  UserRole get role => _role;

  bool login(String password) {
    if (password == '123456') {
      _role = UserRole.admin;
      notifyListeners();
      return true;
    } else if (password == '123') {
      _role = UserRole.employee;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    notifyListeners();
  }
}
