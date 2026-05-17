import 'dart:io';
import 'package:capstone_project/models/profile_data.dart';
import 'package:capstone_project/services/mongo_data_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final ProfileData profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _image;
  final picker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _yearLevelController;
  late final TextEditingController _programController;
  late final TextEditingController _schoolEmailController;
  late final TextEditingController _personalEmailController;
  late final TextEditingController _passController;
  late final TextEditingController _confirmPassController;

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  // Dark Navy color from your UI
  final Color darkNavy = const Color(0xFF233446);
  final Color headerBlue = const Color(0xFF5D7E97);

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _studentIdController = TextEditingController(text: profile.studentId);
    _yearLevelController = TextEditingController(text: profile.yearLevel);
    _programController = TextEditingController(text: profile.program);
    _schoolEmailController = TextEditingController(text: profile.schoolEmail);
    _personalEmailController =
        TextEditingController(text: profile.personalEmail);
    _passController = TextEditingController();
    _confirmPassController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    _yearLevelController.dispose();
    _programController.dispose();
    _schoolEmailController.dispose();
    _personalEmailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passController.text.trim();
    final confirm = _confirmPassController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First and last name are required.')),
      );
      return;
    }

    if (password.isNotEmpty || confirm.isNotEmpty) {
      if (password.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 chars.')),
        );
        return;
      }
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final updated = ProfileData(
      firstName: firstName,
      lastName: lastName,
      studentId: _studentIdController.text.trim(),
      yearLevel: _yearLevelController.text.trim(),
      program: _programController.text.trim(),
      schoolEmail: _schoolEmailController.text.trim(),
      personalEmail: _personalEmailController.text.trim(),
      role: widget.profile.role,
    );

    try {
      final saved = await MongoDataApiService.instance.updateProfile(
        profile: updated,
        newPassword: password.isNotEmpty ? password : null,
      );
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAlumni = widget.profile.isAlumni;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slight off-white background
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 60.h),
            _buildImagePickerButton(),
            
            // Basic Information Card
            _buildSectionCard(
              title: "Basic Information",
              children: [
                _buildLabel("First Name:"),
                _buildTextField(_firstNameController),
                _buildLabel("Last Name:"),
                _buildTextField(_lastNameController),
                if (!isAlumni) ...[
                  _buildLabel("Student ID:"),
                  _buildTextField(_studentIdController),
                ],
                _buildLabel(isAlumni ? "Year Graduated:" : "Year level:"),
                _buildTextField(_yearLevelController),
                _buildLabel("Program:"),
                _buildTextField(_programController),
                if (!isAlumni) ...[
                  _buildLabel("School Email:"),
                  _buildTextField(_schoolEmailController),
                ],
                _buildLabel("Login Email:"),
                _buildTextField(_personalEmailController),
                SizedBox(height: 10.h),
              ],
            ),

            // Change Password Card
            _buildSectionCard(
              title: "Change Password",
              children: [
                _buildLabel("New Password"),
                _buildPasswordField(_passController, _obscurePass, () {
                  setState(() => _obscurePass = !_obscurePass);
                }),
                _buildLabel("Confirm Password"),
                _buildPasswordField(_confirmPassController, _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                }),
                SizedBox(height: 10.h),
              ],
            ),

            // Final Confirmation Button
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30.h),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkNavy,
                  fixedSize: Size(250.w, 45.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 160.h,
          width: double.infinity,
          color: headerBlue,
          padding: EdgeInsets.only(left: 20.w, top: 50.h),
          child: Text(
            "Profile",
            style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: -50.h,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            padding: EdgeInsets.all(5.r),
            child: CircleAvatar(
              radius: 55.r,
              backgroundColor: headerBlue,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null ? Icon(Icons.person, size: 80.r, color: Colors.black) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 15.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildImagePickerButton() {
    return ElevatedButton(
      onPressed: _pickImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: darkNavy,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      ),
      child: Text("Change Profile", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h, top: 10.h),
      child: Text(text, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFFDFDFD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade400)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, bool obscure, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18.r),
          onPressed: onToggle,
        ),
      ),
    );
  }
}