import '../constants.dart';
import '../widgets/custom_font.dart';
import '../widgets/custom_inkwell_button.dart';
import '../widgets/custom_textformfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/gestures.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController schoolEmailController = TextEditingController();
  TextEditingController studentIdController = TextEditingController();
  TextEditingController yearLevelController = TextEditingController();
  TextEditingController programController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  void _showValidationAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          title: Text("Notice",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
          content: Text(message, style: TextStyle(fontSize: 14.sp)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK",
                  style: TextStyle(
                      color: Color(0xFF233446), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleRegister() {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    final complexityRegex = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$%^&*(),.?":{}|<>]).*$');

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showValidationAlert("All fields are required.");
      return;
    }

    if (pass.length < 8) {
      _showValidationAlert("Password must be at least 8 characters long.");
      return;
    }

    if (!complexityRegex.hasMatch(pass)) {
      _showValidationAlert(
          "Password must include an uppercase, lowercase, number, and special character.");
      return;
    }

    if (pass != confirm) {
      _showValidationAlert("The passwords you entered do not match.");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created successfully!")),
    );

    Navigator.pop(context);
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
                  height: 50.h,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image, size: 10.h),
                ),
              ),
            ),
          ),

          // Bottom Section: Registration Form
          Expanded(
            flex: 6,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        CustomFont(
                          text: 'Create an Account',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        SizedBox(height: 25.h),

                        // First Name
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: firstNameController,
                          hintText: 'First Name',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Last Name
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: lastNameController,
                          hintText: 'Last Name',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Date of Birth
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: dateOfBirthController,
                          hintText: 'Date of Birth',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Email
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: emailController,
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
                        SizedBox(height: 15.h),

                        // School Email
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: schoolEmailController,
                          hintText: 'School Email',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Student ID
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: studentIdController,
                          hintText: 'Student ID',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Year Level
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: yearLevelController,
                          hintText: 'Year Level',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Program
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: programController,
                          hintText: 'Program',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                        ),
                        SizedBox(height: 15.h),

                        // Confirm Password
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: confirmPasswordController,
                          isObscure: _isConfirmPasswordObscure,
                          hintText: 'Confirm Password',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _isConfirmPasswordObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: FB_DARK_PRIMARY,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordObscure =
                                    !_isConfirmPasswordObscure;
                              });
                            },
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter confirm password'
                              : null,
                        ),
                        SizedBox(height: 15.h),

                        // Password
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: passwordController,
                          isObscure: _isPasswordObscure,
                          hintText: 'Password',
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
                          suffixIcon: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _isPasswordObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: FB_DARK_PRIMARY,
                              size: 20.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscure = !_isPasswordObscure;
                              });
                            },
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter password'
                              : null,
                        ),
                        SizedBox(height: 25.h),

                        // Register Button
                        CustomInkwellButton(
                          onTap: _handleRegister,
                          height: 55.h,
                          width: double.infinity,
                          buttonName: 'Register',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          bgColor: FB_DARK_PRIMARY,
                          fontColor: Colors.white,
                        ),
                        SizedBox(height: 20.h),

                        // Login Link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Already have an account? ',
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
                        SizedBox(height: 20.h),
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
