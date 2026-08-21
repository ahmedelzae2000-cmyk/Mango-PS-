import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider with ChangeNotifier {
  bool _isDarkMode = true;
  String _userRole = 'موظف'; // 'مدير' أو 'موظف'
  String _userName = '';
  String? _bgImagePath;

  bool get isDarkMode => _isDarkMode;
  String get userRole => _userRole;
  String get userName => _userName;
  String? get bgImagePath => _bgImagePath;

  AppProvider() {
    _loadPreferences();
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }

  void setUser(String name, String role) {
    _userName = name;
    _userRole = role;
    notifyListeners();
  }

  void setBackgroundImage(String? path) async {
    _bgImagePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      prefs.setString('bgImagePath', path);
    } else {
      prefs.remove('bgImagePath');
    }
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _bgImagePath = prefs.getString('bgImagePath');
    notifyListeners();
  }
}
