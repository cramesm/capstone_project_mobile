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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final role = widget.isStudent ? 'student' : 'alumni';

    try {
      final isValid = await MongoDataApiService.instance.login(
        email: email,
        password: password,
        role: role,
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
                color: fbPrimary,
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
                          bgColor: fbTextColorWhite,
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: fbDarkPrimary,
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
                          bgColor: fbTextColorWhite,
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: fbDarkPrimary,
                            validator: (value) => value == null || value.isEmpty
                              ? 'Enter password'
                              : null,
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: fbDarkPrimary,
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
                                color: fbBackgroundLight,
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
                          fontColor: fbTextColorWhite,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          bgColor: fbDarkPrimary,
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
                                        color: fbBackgroundLight,
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
                                      color: fbBackgroundLight,
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
