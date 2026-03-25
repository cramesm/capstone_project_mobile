import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

  class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _image;
  final picker = ImagePicker();

  // Controllers with placeholders based on your design
  final TextEditingController _firstNameController = TextEditingController(text: "Alyssa");
  final TextEditingController _lastNameController = TextEditingController(text: "Cruz");
  final TextEditingController _studentIdController = TextEditingController(text: "2024-123346");
  final TextEditingController _yearLevelController = TextEditingController(text: "2nd Year");
  final TextEditingController _programController = TextEditingController(text: "BSIT-MWA");
  final TextEditingController _schoolEmailController = TextEditingController(text: "alyssac@school.edu.ph");
  final TextEditingController _personalEmailController = TextEditingController(text: "alyssacruz1@email.com");
  
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Dark Navy color from your UI
  final Color darkNavy = const Color(0xFF233446);
  final Color headerBlue = const Color(0xFF5D7E97);

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _handleSave() {
    // Validation logic remains the same...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _buildLabel("Student ID:"),
                _buildTextField(_studentIdController),
                _buildLabel("Year level:"),
                _buildTextField(_yearLevelController),
                _buildLabel("Program:"),
                _buildTextField(_programController),
                _buildLabel("School Email:"),
                _buildTextField(_schoolEmailController),
                _buildLabel("Personal Email:"),
                _buildTextField(_personalEmailController),
                SizedBox(height: 10.h),
                _buildInlineSaveButton(),
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
                _buildInlineSaveButton(),
              ],
            ),

            // Final Confirmation Button
            Padding(
              padding: EdgeInsets.symmetric(vertical: 30.h),
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkNavy,
                  fixedSize: Size(250.w, 45.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                ),
                child: Text("Confirm Changes", style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
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

  Widget _buildInlineSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: () {}, // Save partial section
        style: ElevatedButton.styleFrom(
          backgroundColor: darkNavy,
          minimumSize: Size(80.w, 35.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        ),
        child: Text("Save", style: TextStyle(color: Colors.white, fontSize: 13.sp)),
      ),
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