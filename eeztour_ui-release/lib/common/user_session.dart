// common/user_session.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static UserSession? _instance;
  static SharedPreferences? _prefs;

  UserSession._();

  static Future<UserSession> getInstance() async {
    if (_instance == null) {
      _instance = UserSession._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  String? get accessToken => _prefs?.getString('access_token');
  String? get tokenType => _prefs?.getString('token_type');
  int? get userId => _prefs?.getInt('user_id');
  int? get roleId => _prefs?.getInt('role_id');
  String? get username => _prefs?.getString('username');
  String? get email => _prefs?.getString('email');
  String? get phone => _prefs?.getString('phone');
  bool get rememberMe => _prefs?.getBool('remember_me') ?? false;

  // Check if user is logged in
  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  // Get user info as a map
  Map<String, dynamic> get userInfo => {
    'user_id': userId,
    'role_id': roleId,
    'username': username,
    'email': email,
    'phone': phone,
    'access_token': accessToken,
    'token_type': tokenType,
  };

  // Update specific user data
  Future<void> updateUserData({
    String? username,
    String? email,
    String? phone,
  }) async {
    if (username != null) await _prefs?.setString('username', username);
    if (email != null) await _prefs?.setString('email', email);
    if (phone != null) await _prefs?.setString('phone', phone);
  }

  // Clear all user data (logout)
  Future<void> clearSession() async {
    await _prefs?.clear();
  }

  // Check if user has specific role
  bool hasRole(int roleId) => this.roleId == roleId;

  // Check if user is admin
  bool get isAdmin => hasRole(1);

  // Check if user is regular user (role 3)
  bool get isRegularUser => hasRole(3);

  // Print user session info (for debugging)
  void printSessionInfo() {
    print('=== User Session Info ===');
    print('User ID: $userId');
    print('Role ID: $roleId');
    print('Username: $username');
    print('Email: $email');
    print('Phone: $phone');
    print('Is Logged In: $isLoggedIn');
    print('Remember Me: $rememberMe');
    print('========================');
  }
}