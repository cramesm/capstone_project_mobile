import 'package:capstone_project/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_textformfield.dart';
import '../constants.dart';
import '../widgets/custom_font.dart';
import 'package:flutter/gestures.dart';
import '../widgets/custom_inkwell_button.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());

  final TextEditingController _emailController = TextEditingController();

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _verifyOTPEmail() {
    String otp = _otpControllers.map((controller) => controller.text).join();
    String email = _emailController.text.trim();

    if (email.isEmpty && otp.length < 6) {
      _showValidationError("Email and OTP are both required.");
      return;
    }

    if (otp.length < 6) {
      _showValidationError('Please fill in all 6 digits.');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
      );
    }

    if (email.isEmpty) {
      _showValidationError("Email is required.");
      return;
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

          // Bottom Section: Password Recovery Form
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: FB_PRIMARY,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
            //  child: SingleChildScrollView(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 25.w, vertical: 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      CustomFont(
                        text: 'Forgot Password',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Enter your registered email to receive One-Time Password (OTP)',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Email Field
                      CustomTextFormField(
                        height: ScreenUtil().setHeight(10),
                        width: ScreenUtil().setWidth(10),
                        controller: _emailController,
                        hintText: 'Email',
                        fontSize: 14.sp,
                        hintTextSize: 14.sp,
                        fontColor: FB_DARK_PRIMARY,
                        bgColor: Colors.white,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            //Input code for email verification
                          },
                          child: Text(
                            'Verify email',
                            style: TextStyle(
                              color: FB_BACKGROUND_LIGHT,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    

                      // OTP Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CustomFont(
                          text: 'Enter OTP',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: FB_TEXT_COLOR_WHITE,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) => _otpBox(index)),
                       
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            //Input code for otp verification from email
                          },
                          child: Text(
                            'Resend code',
                            style: TextStyle(
                              color: FB_BACKGROUND_LIGHT,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Verify Button
                      CustomInkwellButton(
                        onTap: _verifyOTPEmail,
                        height: 55.h,
                        width: double.infinity,
                        buttonName: 'Verify',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        bgColor: FB_DARK_PRIMARY,
                        fontColor: Colors.white,
                      ),
                      SizedBox(height: 10.h),

                      // Back to Login Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Back to ',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: FB_BACKGROUND_LIGHT,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                     
                    ],
                  ),
                ),
              ),
            ),
        
        ],
      ),
    );
  }

  Widget _otpBox(int index) {
    return Container(
      width: 40.w,
      height: 45.h,
      decoration: BoxDecoration(
        color: FB_TEXT_COLOR_WHITE,
        
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: _otpControllers[index],
       
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: FB_DARK_PRIMARY),
        maxLength: 1,
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (!RegExp(r'^[0-9]$').hasMatch(value)) {
              _otpControllers[index].clear();
              _showValidationError('Number only is acceptable on OTP');
            }
          }
        },
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// --- RESET PASSWORD SCREEN ---
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _conPassController = TextEditingController();

  bool _isPasswordVisible = false;

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleResetPassword() {
    String newPass = _newPassController.text.trim();
    String conPass = _conPassController.text.trim();

    final complexityRegex = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$%^&*(),.?":{}|<>]).*$');

    // 1. Check if empty
    if (newPass.isEmpty || conPass.isEmpty) {
      _showValidationError("Please fill in both password fields.");
      return;
    }

    if (newPass.length < 8) {
      _showValidationError("Password must be at least 8 characters long.");
      return;
    }

    if (!complexityRegex.hasMatch(newPass)) {
      _showValidationError(
          "Password must include an uppercase, lowercase, number, and special character.");
      return;
    }

    if (newPass != conPass) {
      _showValidationError("Passwords do not match.");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset successfully!")),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LogInScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _conPassController.dispose();
    super.dispose();
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
                  height: 120.h,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image, size: 50.h),
                ),
              ),
            ),
          ),

          // Bottom Section: Reset Password Form
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
                      EdgeInsets.symmetric(horizontal: 25.w, vertical: 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      CustomFont(
                        text: 'Reset Password',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      SizedBox(height: 25.h),

                      // New Password Field
                      CustomTextFormField(
                        height: ScreenUtil().setHeight(10),
                        width: ScreenUtil().setWidth(10),
                        controller: _newPassController,
                        isObscure: !_isPasswordVisible,
                        hintText: 'New Password',
                        fontSize: 14.sp,
                        hintTextSize: 14.sp,
                        fontColor: FB_DARK_PRIMARY,
                        bgColor: Colors.white,
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter new password'
                            : null,
                      ),
                      SizedBox(height: 20.h),

                      // Confirm Password Field
                      CustomTextFormField(
                        height: ScreenUtil().setHeight(10),
                        width: ScreenUtil().setWidth(10),
                        controller: _conPassController,
                        isObscure: !_isPasswordVisible,
                        hintText: 'Confirm Password',
                        fontSize: 14.sp,
                        hintTextSize: 14.sp,
                        fontColor: FB_DARK_PRIMARY,
                        bgColor: Colors.white,
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter confirm password'
                            : null,
                      ),
                      SizedBox(height: 30.h),

                      // Reset Password Button
                      CustomInkwellButton(
                        onTap: _handleResetPassword,
                        height: 55.h,
                        width: double.infinity,
                        buttonName: 'Reset Password',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        bgColor: FB_DARK_PRIMARY,
                        fontColor: Colors.white,
                      ),
                      SizedBox(height: 20.h),

                      // Back to Login Link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Back to ',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: FB_BACKGROUND_LIGHT,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LogInScreen(),
                                        ),
                                        (route) => false,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
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
