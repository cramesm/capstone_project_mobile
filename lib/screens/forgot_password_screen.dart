import 'package:capstone_project/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_textformfield.dart';
import '../constants.dart';
import '../widgets/custom_font.dart';
import 'package:flutter/gestures.dart';
import '../widgets/custom_inkwell_button.dart';
import '../services/mongo_data_api_service.dart';
import 'package:flutter/services.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  final TextEditingController _emailController = TextEditingController();
  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  String? _devOtp;

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

  Future<void> _requestOtp() async {
    if (_isRequestingOtp) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showValidationError('Please enter a valid registered email.');
      return;
    }

    setState(() {
      _isRequestingOtp = true;
    });

    try {
      final otp = await MongoDataApiService.instance
          .requestPasswordResetOtp(email: email);

      if (!mounted) return;

      setState(() {
        _devOtp = otp;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            otp == null
                ? 'OTP sent to your email.'
                : 'Dev OTP: $otp (disable OTP_DEV_MODE for production)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showValidationError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingOtp = false;
        });
      }
    }
  }

  Future<void> _verifyOTPEmail() async {
    if (_isVerifyingOtp) return;

    final email = _emailController.text.trim();
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (email.isEmpty) {
      _showValidationError('Email is required.');
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showValidationError('Please fill in all 6 OTP digits.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
    });

    try {
      final resetToken = await MongoDataApiService.instance.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(resetToken: resetToken),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showValidationError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _emailController.dispose();
    super.dispose();
  }

  void _handleOtpChange(String value, int index) {
    if (value.isEmpty) {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
      }
      return;
    }

    if (!RegExp(r'^\d$').hasMatch(value)) {
      _otpControllers[index].clear();
      _showValidationError('Number only is acceptable on OTP');
      return;
    }

    if (index < _otpFocusNodes.length - 1) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    } else {
      FocusScope.of(context).unfocus();
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
                          onPressed: _isRequestingOtp ? null : _requestOtp,
                          child: Text(
                            _isRequestingOtp ? 'Sending...' : 'Verify email',
                            style: TextStyle(
                              color: FB_BACKGROUND_LIGHT,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                      if (_devOtp != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            'Dev OTP: $_devOtp',
                            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
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
                          onPressed: _isRequestingOtp ? null : _requestOtp,
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
                        onTap: _isVerifyingOtp ? () {} : _verifyOTPEmail,
                        height: 55.h,
                        width: double.infinity,
                        buttonName: _isVerifyingOtp ? 'Verifying...' : 'Verify',
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
        focusNode: _otpFocusNodes[index],
       
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: FB_DARK_PRIMARY),
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction:
            index == _otpControllers.length - 1 ? TextInputAction.done : TextInputAction.next,
        onChanged: (value) => _handleOtpChange(value, index),
        onSubmitted: (_) {
          if (index < _otpFocusNodes.length - 1) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
          } else {
            FocusScope.of(context).unfocus();
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
  const ResetPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _conPassController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

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

  Future<void> _handleResetPassword() async {
    if (_isSubmitting) return;

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

    setState(() {
      _isSubmitting = true;
    });

    try {
      await MongoDataApiService.instance.resetPassword(
        resetToken: widget.resetToken,
        newPassword: newPass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successfully!")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LogInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showValidationError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
                        buttonName:
                            _isSubmitting ? 'Resetting...' : 'Reset Password',
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
