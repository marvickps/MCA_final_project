// controllers/auth_controller.dart
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/config.dart';

class AuthController {
  static Future<Map<String, dynamic>?> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final accessToken = prefs.getString('access_token');

      if (rememberMe && accessToken != null && accessToken.isNotEmpty) {
        final userData = {
          'access_token': accessToken,
          'token_type': prefs.getString('token_type'),
          'user_id': prefs.getInt('user_id'),
          'role_id': prefs.getInt('role_id'),
          'username': prefs.getString('username'),
          'email': prefs.getString('email'),
          'phone': prefs.getString('phone'),
        };
        return userData;
      }
      return null;
    } catch (e) {
      print('Error checking auto login: $e');
      return null;
    }
  }
  static Future<Map<String, dynamic>> sendOtpForRegistration(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/generate?purpose=registration'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'OTP sent successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Register user
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required int role,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register?otp_code=$otpCode'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'phone': phone,
          'role': role,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Registration successful',
          'data': data,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  static Future<void> saveLoginData(Map<String, dynamic> data, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('token_type', data['token_type'] ?? 'bearer');
      await prefs.setInt('user_id', int.parse(data['user_id'].toString()));
      await prefs.setInt('role_id', int.parse(data['role_id'].toString()));
      await prefs.setString('username', data['username']);
      await prefs.setString('email', data['email'] ?? '');
      await prefs.setString('phone', data['phone'] ?? '');
      await prefs.setBool('remember_me', rememberMe);

      print('Login data saved successfully');
    } catch (e) {
      print('Error saving login data: $e');
      throw Exception('Failed to save login data');
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/generate?purpose=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['detail'] ?? 'Failed to send OTP');
      }

      return {
        'success': true,
        'message': 'OTP sent successfully!',
        'data': data
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null
      };
    }
  }

  static Future<Map<String, dynamic>> loginWithPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['detail'] ?? 'Login failed');
      }

      return {
        'success': true,
        'message': 'Login successful',
        'data': data
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null
      };
    }
  }

  static Future<Map<String, dynamic>> loginWithOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['detail'] ?? 'Login failed');
      }

      return {
        'success': true,
        'message': 'Login successful',
        'data': data
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': null
      };
    }
  }

  static Future<void> logout(BuildContext? context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear user provider if context is available
      if (context != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clearUser();
      }

      print('User logged out successfully');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  static String getNavigationRoute(int roleId) {
    switch (roleId) {
      case 1:
        return '/admin';
      case 3:
        return '/homescreen';
      default:
        return '/home';
    }
  }
}