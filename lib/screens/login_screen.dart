import 'package:capstone_project/screens/forgot_password_screen.dart';
import '../screens/home_screen.dart';
import '../widgets/custom_textformfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../widgets/custom_inkwell_button.dart';
import '../widgets/custom_font.dart';
import 'package:flutter/gestures.dart';
import '../services/mongo_data_api_service.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key, this.isStudent = false});

  final bool isStudent;

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  static const String _tempEmail = 'a@temp.com';
  static const String _tempPassword = 'TempPass!123';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isOtpLoading = false;
  final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final isValid = await MongoDataApiService.instance.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (isValid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login failed: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _promptForOtp({String? otpHint}) async {
    final controller = TextEditingController(text: otpHint ?? '');
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          title: const Text('Verify OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (otpHint != null)
                const Text(
                  'Dev mode: OTP is prefilled.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _handleLoginWithOtp() async {
    if (!_formKey.currentState!.validate() || _isOtpLoading) return;

    setState(() {
      _isOtpLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    String? otpHint;
    try {
      otpHint = await MongoDataApiService.instance.requestLoginOtp(
        email: email,
        password: password,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "OTP request failed: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isOtpLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isOtpLoading = false;
    });

    if (otpHint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email.')),
      );
    }

    final otp = await _promptForOtp(otpHint: otpHint);
    if (otp == null || otp.trim().isEmpty) {
      return;
    }

    setState(() {
      _isOtpLoading = true;
    });

    try {
      await MongoDataApiService.instance.verifyLoginOtp(
        email: email,
        otp: otp.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "OTP verification failed: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOtpLoading = false;
        });
      }
    }
  }

  void _fillTempAccount() {
    emailController.text = _tempEmail;
    passwordController.text = _tempPassword;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top Section: Logo
          Expanded(
            flex: 2,
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: Image.asset(
                  'assets/logo/logo.png',
                  height: 80.h,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image, size: 50.h),
                ),
              ),
            ),
          ),

          // Bottom Section: Login Form
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FB_PRIMARY,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomFont(
                          text: 'Login to your Account',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        SizedBox(height: 30.h),

                        // Email
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: emailController,
                          hintText: 'Email',
                          bgColor: FB_TEXT_COLOR_WHITE,
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Enter email';
                            }
                            if (!_emailRegex.hasMatch(email)) {
                              return 'Enter valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),

                        // Password
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                  
                          controller: passwordController,
                          isObscure: !_isPasswordVisible,
                          hintText: 'Password',
                          bgColor: FB_TEXT_COLOR_WHITE,
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter password'
                              : value.trim().length < 8
                                ? 'Password must be at least 8 characters'
                                : null,
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: FB_DARK_PRIMARY,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const PasswordScreen()),
                              );
                            },
                            style:
                                TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: FB_BACKGROUND_LIGHT,
                                fontSize: 12.sp,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),

                        // LOGIN BUTTON
                        CustomInkwellButton(
                          onTap: _handleLogin,
                          height: 55.h,
                          width: ScreenUtil().screenWidth,
                          buttonName: _isLoading ? 'Logging in...' : 'Login',
                          fontColor: FB_TEXT_COLOR_WHITE,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          bgColor: FB_DARK_PRIMARY,
                        ),

                        SizedBox(height: 12.h),

                        CustomInkwellButton(
                          onTap: _handleLoginWithOtp,
                          height: 50.h,
                          width: ScreenUtil().screenWidth,
                          buttonName: _isOtpLoading
                              ? 'Requesting OTP...'
                              : 'Login with OTP',
                          fontColor: FB_DARK_PRIMARY,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          bgColor: FB_BACKGROUND_LIGHT,
                        ),

                        SizedBox(height: 12.h),

                        CustomInkwellButton(
                          onTap: _fillTempAccount,
                          height: 45.h,
                          width: ScreenUtil().screenWidth,
                          buttonName: 'Use Temp Account',
                          fontColor: FB_DARK_PRIMARY,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          bgColor: FB_BACKGROUND_LIGHT,
                        ),

                        SizedBox(height: 25.h),

                        // Footer
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!widget.isStudent)
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Sign up',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                        color: FB_BACKGROUND_LIGHT,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => Navigator.pushNamed(
                                            context, '/register'),
                                    ),
                                  ],
                                ),
                              ),
                            if (!widget.isStudent) SizedBox(height: 15.h),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Are you an Alumni or Student? ",
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Choose Here',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                      color: FB_BACKGROUND_LIGHT,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => Navigator.pushNamed(
                                          context, '/choose'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
