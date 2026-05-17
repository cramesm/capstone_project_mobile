import '../constants.dart';
import '../widgets/custom_font.dart';
import '../widgets/custom_inkwell_button.dart';
import '../widgets/custom_textformfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/gestures.dart';
import '../services/mongo_data_api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final RegExp _nameRegex = RegExp(r'^[A-Za-z][A-Za-z\s\-]{1,49}$');
  final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController yearGraduatedController = TextEditingController();
  final TextEditingController programController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode _programFocusNode = FocusNode();
  final FocusNode _yearGraduatedFocusNode = FocusNode();

  final int _currentYear = DateTime.now().year;
  final List<String> _programOptions = [
    'BSIT',
    'BSIT-MWA',
    'BSCS',
    'BSIS',
    'BSECE',
    'BSCE',
    'BSA',
    'BSBA',
    'BSHM',
    'BSTM',
    'BEED',
    'BSED',
  ];
  late final List<String> _graduationYears = List.generate(
    _currentYear - 1980 + 1,
    (index) => (_currentYear - index).toString(),
  );

  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _isSubmitting = false;
  bool _acceptedTerms = false;

  String _passwordStrength(String password) {
    if (password.isEmpty) return 'Enter password';
    if (password.length < 8) return 'Weak';

    int score = 0;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return 'Weak';
    if (score == 3) return 'Medium';
    return 'Strong';
  }

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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    final program = programController.text.trim();
    final yearGraduated = yearGraduatedController.text.trim();

    final complexityRegex = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$%^&*(),.?":{}|<>]).*$');

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showValidationAlert("All fields are required.");
      return;
    }

    if (program.isEmpty) {
      _showValidationAlert("Please select your program.");
      return;
    }

    if (yearGraduated.isEmpty) {
      _showValidationAlert("Please select your year graduated.");
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

    if (!_acceptedTerms) {
      _showValidationAlert("Please accept Terms and Conditions to continue.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? otpHint;
    try {
      otpHint = await MongoDataApiService.instance.requestRegisterOtp(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        email: email,
        password: pass,
        yearLevel: yearGraduated,
        program: program,
      );
    } catch (e) {
      if (!mounted) return;
      _showValidationAlert(e.toString().replaceFirst('Exception: ', ''));
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (otpHint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP sent to your email.")),
      );
    }

    final otp = await _promptForOtp(otpHint: otpHint);
    if (otp == null || otp.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await MongoDataApiService.instance.verifyRegisterOtp(
        email: email,
        otp: otp.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showValidationAlert(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required List<String> options,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return options;
        }
        return options.where(
          (option) => option.toLowerCase().contains(query),
        );
      },
      fieldViewBuilder: (context, textController, node, onFieldSubmitted) {
        return SizedBox(
          height: 60.h,
          width: double.infinity,
          child: TextFormField(
            controller: textController,
            focusNode: node,
            validator: validator,
            keyboardType: keyboardType,
            cursorColor: FB_DARK_PRIMARY,
            style: TextStyle(fontSize: 14.sp, color: FB_DARK_PRIMARY),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 14.sp,
                color: FB_DARK_PRIMARY.withOpacity(0.75),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8.r),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 200.h),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option, style: TextStyle(fontSize: 13.sp)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    yearGraduatedController.dispose();
    programController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _programFocusNode.dispose();
    _yearGraduatedFocusNode.dispose();
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
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return 'Enter first name';
                            if (!_nameRegex.hasMatch(input)) {
                              return 'Use letters only (2-50 chars)';
                            }
                            return null;
                          },
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
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return 'Enter last name';
                            if (!_nameRegex.hasMatch(input)) {
                              return 'Use letters only (2-50 chars)';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15.h),

                        // Email
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          fontSize: 14.sp,
                          hintTextSize: 14.sp,
                          fontColor: FB_DARK_PRIMARY,
                          bgColor: Colors.white,
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
                        SizedBox(height: 15.h),

                        // Year Graduated
                        _buildAutocompleteField(
                          controller: yearGraduatedController,
                          focusNode: _yearGraduatedFocusNode,
                          options: _graduationYears,
                          hintText: 'Year Graduated',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return 'Select year graduated';
                            return null;
                          },
                        ),
                        SizedBox(height: 15.h),

                        // Program
                        _buildAutocompleteField(
                          controller: programController,
                          focusNode: _programFocusNode,
                          options: _programOptions,
                          hintText: 'Program',
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return 'Select program';
                            return null;
                          },
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
                              : value.trim() != passwordController.text.trim()
                                ? 'Passwords do not match'
                                : null,
                        ),
                        SizedBox(height: 15.h),

                        // Password
                        CustomTextFormField(
                          height: ScreenUtil().setHeight(10),
                          width: ScreenUtil().setWidth(10),
                          controller: passwordController,
                          onChanged: (_) => setState(() {}),
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
                          validator: (value) {
                            final password = value?.trim() ?? '';
                            if (password.isEmpty) return 'Enter password';
                            if (password.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Password strength: ${_passwordStrength(passwordController.text.trim())}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              side: const BorderSide(color: Colors.white70),
                              checkColor: FB_DARK_PRIMARY,
                              fillColor:
                                  WidgetStateProperty.all(Colors.white),
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the Terms and Conditions',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25.h),

                        // Register Button
                        CustomInkwellButton(
                          onTap: _handleRegister,
                          height: 55.h,
                          width: double.infinity,
                          buttonName: _isSubmitting ? 'Registering...' : 'Register',
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
