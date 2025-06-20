import 'package:flutter/material.dart';
import 'user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

// const String baseUrl = 'https://event.eeztour.com/api';
// const String baseUrl = 'http://192.168.145.179:8000/api';
const String baseUrl = 'http://192.168.184.179:8000/api';
// const String baseUrl = 'http://192.168.137.48:8000/api';
// etube002@gmail.com
//123456


class UserProvider extends ChangeNotifier {
  int? _userId;
  String? _accessToken;
  String? _tokenType;
  String? _username;
  String? _email;
  int? _roleId;

  // Getters
  int? get userId => _userId;
  String? get accessToken => _accessToken;
  String? get tokenType => _tokenType;
  String? get username => _username;
  String? get email => _email;
  int? get roleId => _roleId;

  // Get authorization header for API calls
  Map<String, String> get authHeaders {
    if (_accessToken != null && _tokenType != null) {
      return {
        'Authorization': '${_tokenType} $_accessToken',
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  // Load user data from SharedPreferences
  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id');
      _accessToken = prefs.getString('access_token');
      _tokenType = prefs.getString('token_type');
      _username = prefs.getString('username');
      _email = prefs.getString('email');
      _roleId = prefs.getInt('role_id');

      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Set user data (called after successful login)
  Future<void> setUser({
    required int userId,
    required String accessToken,
    required String tokenType,
    required String username,
    required String email,
    required int roleId,
  }) async {
    _userId = userId;
    _accessToken = accessToken;
    _tokenType = tokenType;
    _username = username;
    _email = email;
    _roleId = roleId;

    notifyListeners();
  }

  // Clear user data (called during logout)
  void clearUser() {
    _userId = null;
    _accessToken = null;
    _tokenType = null;
    _username = null;
    _email = null;
    _roleId = null;

    notifyListeners();
  }

  // Update access token (useful for token refresh)
  Future<void> updateAccessToken(String newToken, [String? newTokenType]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newToken);
      if (newTokenType != null) {
        await prefs.setString('token_type', newTokenType);
      }

      _accessToken = newToken;
      if (newTokenType != null) {
        _tokenType = newTokenType;
      }

      notifyListeners();
    } catch (e) {
      print('Error updating access token: $e');
    }
  }
}

