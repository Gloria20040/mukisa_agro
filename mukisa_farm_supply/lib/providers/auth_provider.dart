import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser != null && _currentUser!['role'] == 'admin';

  Future<String?> login(String username, String password) async {
    try {
      final user = await AuthService.login(username, password);
      if (user == null) return 'Invalid username or password';
      _currentUser = user;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Login error';
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final ok = await AuthService.changePassword(userId, currentPassword, newPassword);
      return ok;
    } catch (_) {
      return false;
    }
  }

  // Admin helper: set password for a user
  Future<bool> adminSetPassword(int userId, String newPassword) async {
    try {
      final ok = await AuthService.setPasswordForUser(userId, newPassword);
      return ok;
    } catch (_) {
      return false;
    }
  }
}
