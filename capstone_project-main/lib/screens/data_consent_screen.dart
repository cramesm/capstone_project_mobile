import 'package:capstone_project/screens/payment_details_screen.dart';
import 'package:capstone_project/screens/request_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';


class DataConsentScreen extends StatefulWidget {
  const DataConsentScreen({super.key});

  @override
  State<DataConsentScreen> createState() => _DataConsentScreenState();
}

class _DataConsentScreenState extends State<DataConsentScreen> {
  bool _hasConsented = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D7E97),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 30.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Data Consent Form",
          style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Request Processing Steps Card
            _buildInfoCard(
              title: "Request Processing Steps",
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepText("Step 1: Request"),
                  _stepText("Step 2: Verification and Billing"),
                  _stepText("Step 3: Payment"),
                  _stepText("Step 4: Payment Verification and Confirmation"),
                  _stepText("Step 5: Document Processing"),
                  _stepText("Step 7: Document Issuance"),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Data Privacy Consent Card
            _buildInfoCard(
              title: "Data Privacy Consent",
              content: Column(
                children: [
                  Text(
                    "By using VerifiTOR and submitting a Transcript of Records (TOR) request, I voluntarily provide my personal information and academic details to the system and authorize the Registrar's Office to collect, process, store, and use such information...",
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87, height: 1.4),
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasConsented,
                        activeColor: const Color(0xFF5D7E97),
                        onChanged: (val) => setState(() => _hasConsented = val!),
                      ),
                      Expanded(
                        child: Text(
                          "I hereby consent to the collection and processing of my personal and academic information in compliance with the Data Privacy Act of 2012 (RA 10173).",
                          style: TextStyle(fontSize: 10.sp),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),

            // Navigation Button
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _hasConsented 
                  ? () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const RequestFormScreen())
                    ) 
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF233446),
                  padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text("Next", style: TextStyle(color: Colors.white, fontSize: 18.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 15.h),
          content,
        ],
      ),
    );
  }

  Widget _stepText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
    );
  }
}