// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/config.dart';
import '../controllers/auth_controller.dart';
import '../widget/login_widgets.dart';
import '../../../common/user_session.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);


  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (index) => FocusNode());

  bool _otpSent = false;
  bool _isLoading = false;
  String _loginMethod = 'password';
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final userData = await AuthController.checkAutoLogin();
    if (userData != null && userData['role_id'] != null) {
      // Set user data in provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(
        userId: userData['user_id'] ?? 0,
        accessToken: userData['access_token'] ?? '',
        tokenType: userData['token_type'] ?? 'bearer',
        username: userData['username'] ?? '',
        email: userData['email'] ?? '',
        roleId: userData['role_id'] ?? 0,
      );

      final route = AuthController.getNavigationRoute(userData['role_id']);
      Navigator.pushReplacementNamed(context, route);
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getOtpValue() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleSendOtp() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthController.sendOtp(_emailController.text);

    if (result['success']) {
      _showSnackBar(result['message']);
      setState(() => _otpSent = true);
    } else {
      _showSnackBar(result['message']);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleLogin() async {
    if (_loginMethod == 'otp' && _getOtpValue().length != 6) {
      _showSnackBar('Please enter complete OTP');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_loginMethod == 'otp') {
      result = await AuthController.loginWithOtp(
        _emailController.text,
        _getOtpValue(),
      );
    } else {
      result = await AuthController.loginWithPassword(
        _emailController.text,
        _passwordController.text,
      );
    }

    if (result['success']) {
      // Save login data to SharedPreferences
      await AuthController.saveLoginData(result['data'], _rememberMe);

      // Update UserProvider with login data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(
        userId: int.parse(result['data']['user_id'].toString()),
        accessToken: result['data']['access_token'],
        tokenType: result['data']['token_type'] ?? 'bearer',
        username: result['data']['username'],
        email: result['data']['email'] ?? '',
        roleId: int.parse(result['data']['role_id'].toString()),
      );

      // Navigate based on role
      final roleId = result['data']['role_id'];
      if (roleId != null) {
        final route = AuthController.getNavigationRoute(
            int.parse(roleId.toString())
        );
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      _showSnackBar(result['message']);
    }

    setState(() => _isLoading = false);
  }
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ForgotPasswordModal(),
    );
  }

  Widget _buildPasswordLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Password',
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          controller: _passwordController,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFD14343),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Color(0xFFD14343),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Login',
          onPressed: _handleLogin,
          isLoading: _isLoading,
          loadingText: 'Logging in...',
        ),
      ],
    );
  }

  Widget _buildOtpInputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Send OTP',
          onPressed: _handleSendOtp,
          isLoading: _isLoading,
          loadingText: 'Sending OTP...',
          icon: Icons.send,
        ),
      ],
    );
  }

  Widget _buildOtpVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        OtpInputFields(
          controllers: _otpControllers,
          focusNodes: _otpFocusNodes,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Verify OTP',
          onPressed: _handleLogin,
          isLoading: _isLoading,
          loadingText: 'Verifying...',
        ),
        const SizedBox(height: 24),
        const Text(
          'Didn\'t receive the OTP?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        TextButton.icon(
          onPressed: _isLoading ? null : _handleSendOtp,
          icon: const Icon(
            Icons.refresh,
            color: Color(0xFFD14343),
            size: 18,
          ),
          label: const Text(
            'Resend OTP',
            style: TextStyle(
              color: Color(0xFFD14343),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _otpSent = false;
              _loginMethod = 'password';
              for (var controller in _otpControllers) {
                controller.clear();
              }
            });
          },
          child: const Text(
            'Back to Login',
            style: TextStyle(
              color: Color(0xFFD14343),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: LoginCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - different for OTP verification screen
                    if (_loginMethod == 'otp' && _otpSent)
                      LoginHeader(
                        title: 'Enter OTP',
                        subtitle: 'We\'ve sent a one time password to your email.',
                        icon: Icons.shield_outlined,
                        iconSize: 40,
                      )
                    else
                      LoginHeader(
                        title: 'Welcome Back!!',
                        subtitle: 'Please Login to your account.',
                        icon: Icons.person_outline,
                      ),

                    const SizedBox(height: 32),

                    // Login method tabs (only show if OTP not sent)
                    if (!_otpSent) ...[
                      LoginMethodTabs(
                        selectedMethod: _loginMethod,
                        onMethodChanged: (method) {
                          setState(() {
                            _loginMethod = method;
                            _otpSent = false;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Form content
                    if (_loginMethod == 'password')
                      _buildPasswordLoginForm()
                    else if (_loginMethod == 'otp' && !_otpSent)
                      _buildOtpInputForm()
                    else if (_loginMethod == 'otp' && _otpSent)
                        _buildOtpVerificationForm(),

                    // Registration link (only show for password login and when OTP not sent)
                    if ((_loginMethod == 'password' || !_otpSent) && !(_loginMethod == 'otp' && _otpSent)) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFFD14343),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}