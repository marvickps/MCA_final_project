// screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/config.dart';
import '../controllers/auth_controller.dart';
import '../widget/login_widgets.dart';
import '../../../common/user_session.dart';

class RegisterScreenToggle extends StatefulWidget {
  const RegisterScreenToggle({Key? key}) : super(key: key);

  @override
  State<RegisterScreenToggle> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreenToggle> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
  List.generate(6, (index) => FocusNode());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;
  int _currentStep = 1;
  String _userType = 'user'; // 'user' or 'travel_operator'

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getOtpValue() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (!_termsAccepted) {
      _showSnackBar('Please accept the Terms of Service and Privacy Policy');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call your API to send OTP
      final result = await AuthController.sendOtpForRegistration(_emailController.text);

      if (result['success']) {
        _showSnackBar('Verification code sent to ${_emailController.text}');
        setState(() {
          _otpSent = true;
          _currentStep = 2;
        });
      } else {
        _showSnackBar(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    if (_getOtpValue().length != 6) {
      _showSnackBar('Please enter complete OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final role = _userType == 'user' ? 2 : 3;

      final result = await AuthController.registerUser(
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        phone: _phoneController.text,
        role: role,
        otpCode: _getOtpValue(),
      );

      if (result['success']) {
        setState(() {
          _otpVerified = true;
          _currentStep = 3;
        });
      } else {
        _showSnackBar(result['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print(e);
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUserTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _userType = 'user'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _userType == 'user' ? const Color(0xFFD14343) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'User',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _userType == 'user' ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _userType = 'travel_operator'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _userType == 'travel_operator' ? const Color(0xFFD14343) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Travel Operator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _userType == 'travel_operator' ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _currentStep >= 1 ? const Color(0xFFD14343) : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                bottomLeft: Radius.circular(2),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _currentStep >= 2 ? const Color(0xFFD14343) : Colors.grey[300],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: _currentStep >= 3 ? const Color(0xFFD14343) : Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildUserTypeToggle(),
        const SizedBox(height: 24),

        CustomTextField(
          label: 'Email Address',
          hintText: 'yourname@example.com',
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
          label: 'Phone Number',
          hintText: '+91 xxxxxxxxxx',
          prefixIcon: Icons.phone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        CustomTextField(
          label: 'Password',
          hintText: 'Create a strong password',
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
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        CustomTextField(
          label: 'Confirm Password',
          hintText: 'Confirm your password',
          prefixIcon: Icons.lock_outline,
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _termsAccepted,
              onChanged: (value) {
                setState(() {
                  _termsAccepted = value ?? false;
                });
              },
              activeColor: const Color(0xFFD14343),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _termsAccepted = !_termsAccepted;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      children: [
                        const TextSpan(text: 'I accept the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: const Color(0xFFD14343),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: const Color(0xFFD14343),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        CustomButton(
          text: 'Continue & Verify Email',
          onPressed: _sendOtp,
          isLoading: _isLoading,
          loadingText: 'Sending...',
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD14343).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: const Color(0xFFD14343),
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'Verification code sent!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD14343),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We\'ve sent a verification code to ${_emailController.text}',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFD14343).withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        OtpInputFields(
          controllers: _otpControllers,
          focusNodes: _otpFocusNodes,
        ),
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1;
                    _otpSent = false;
                    for (var controller in _otpControllers) {
                      controller.clear();
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Create Account',
                onPressed: _verifyOtpAndRegister,
                isLoading: _isLoading,
                loadingText: 'Creating Account...',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          'Didn\'t receive the code?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        TextButton.icon(
          onPressed: _isLoading ? null : _sendOtp,
          icon: const Icon(
            Icons.refresh,
            color: Color(0xFFD14343),
            size: 18,
          ),
          label: const Text(
            'Resend Code',
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

  Widget _buildStep3() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Registration Successful!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your account has been created successfully.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        CustomButton(
          text: 'Go to Login',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
      ],
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case 2:
        return 'Verify Your Email';
      case 3:
        return 'Welcome!';
      default:
        return 'Create Your Account';
    }
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case 2:
        return 'We\'ve sent a verification code to your email.';
      case 3:
        return '';
      default:
        return 'Join us and start your journey.';
    }
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
                    LoginHeader(
                      title: _getTitle(),
                      subtitle: _getSubtitle(),
                      icon: _currentStep == 2
                          ? Icons.shield_outlined
                          : _currentStep == 3
                          ? Icons.celebration_outlined
                          : Icons.person_add_outlined,
                      iconSize: _currentStep == 2 ? 40 : 32,
                    ),

                    if (_currentStep != 3) ...[
                      const SizedBox(height: 24),
                      _buildStepIndicator(),
                    ],

                    const SizedBox(height: 32),

                    if (_currentStep == 1)
                      _buildStep1()
                    else if (_currentStep == 2)
                      _buildStep2()
                    else if (_currentStep == 3)
                        _buildStep3(),

                    if (_currentStep == 1) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: const Text(
                              'Sign In',
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