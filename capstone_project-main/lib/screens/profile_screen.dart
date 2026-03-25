import 'package:capstone_project/screens/edit_profile_screen.dart';
import 'package:capstone_project/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors based on your theme
    final Color headerBlue = const Color(0xFF5D7E97);
    final Color darkNavy = const Color(0xFF233446);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section: Header and Avatar
            Stack(
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
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 32.sp, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50.h,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white, 
                      shape: BoxShape.circle
                    ),
                    padding: EdgeInsets.all(5.r),
                    child: CircleAvatar(
                      radius: 55.r,
                      backgroundColor: headerBlue,
                      child: Icon(Icons.person, size: 80.r, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 70.h),

            // Basic Information Card (View Only)
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Basic Information",
                    style: TextStyle(
                      fontSize: 18.sp, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildInfoRow("Name:", "Alyssa Cruz"),
                  _buildInfoRow("Student ID:", "2024-123346"),
                  _buildInfoRow("Year level:", "2nd Year"),
                  _buildInfoRow("Program:", "BSIT-MWA"),
                  _buildInfoRow("School Email:", "alyssac@school.edu.ph"),
                  _buildInfoRow("Personal Email:", "alyssacruz1@email.com"),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // Edit Profile Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkNavy,
                fixedSize: Size(180.w, 45.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r)
                ),
              ),
              child: Text(
                "Edit profile",
                style: TextStyle(color: Colors.white, fontSize: 20.sp),
              ),
            ),

            SizedBox(height: 80.h),

            // Log out Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkNavy,
                fixedSize: Size(180.w, 45.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r)
                ),
              ),
              child: Text(
                "Log out",
                style: TextStyle(color: Colors.white, fontSize: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build the row labels and values
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp, 
                color: Colors.black, 
                fontWeight: FontWeight.w500
              ),
            ),
          ),
        ],
      ),
    );
  }
}