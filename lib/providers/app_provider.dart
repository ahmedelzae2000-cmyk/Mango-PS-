import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  bool _isDarkMode = true;
  String _userName = 'المدير';
  String _userRole = 'مدير';

  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;
  String get userRole => _userRole;

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setUserDetails(String name, String role) {
    _userName = name;
    _userRole = role;
    notifyListeners();
  }
}
