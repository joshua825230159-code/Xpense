import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xpense/models/user_model.dart';
import 'package:xpense/services/sqlite_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SqliteService _dbService = SqliteService.instance;

  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  static const String _userIdKey = 'userId';

  AuthViewModel() {
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_userIdKey)) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final userId = prefs.getInt(_userIdKey);
    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _user = await _dbService.getUserById(userId);
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    try {
      final user = await _dbService.login(username, password);
      if (user != null) {
        _user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userIdKey, user.id!);
        notifyListeners();
        return null; // Success
      } else {
        return 'Invalid username or password.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String username, String password) async {
    try {
      final user = await _dbService.registerUser(username, password);
      if (user != null) {
        // Automatically log in after registration
        return await login(username, password);
      } else {
        return 'Username already exists.';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    notifyListeners();
  }
}
