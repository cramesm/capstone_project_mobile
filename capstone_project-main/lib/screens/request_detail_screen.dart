import 'package:capstone_project/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_font.dart';
import '../screens/request_detail_screen.dart';
import '../screens/payment_details_screen.dart';
import '../screens/pending_screen.dart';


class RequestDetailsScreen extends StatelessWidget {
  final PendingRequest request;
  const RequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D7E97),
        title: const Text("Information of the Request", style: TextStyle(color: FB_TEXT_COLOR_WHITE)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildSectionCard("Student Information", [
              _buildInfoRow("Name:", "Alyssa Cruz"),
              _buildInfoRow("Student ID:", "2024-123346"),
              _buildInfoRow("Program:", "BSIT-MWA"),
              _buildInfoRow("Email:", "alyssac@school.edu.ph"),
            ]),
            SizedBox(height: 15.h),
            _buildSectionCard("Document Details", [
              _buildInfoRow("Type of Document:", request.docName),
              _buildInfoRow("Purpose of Request:", request.purpose),
              _buildInfoRow("Date Requested:", DateFormat('MMMM d, y').format(request.dateCreated)),
            ]),
            SizedBox(height: 15.h),
            _buildSectionCard("Request Status", [
              _buildInfoRow("Date:", DateFormat('MMMM d, y').format(request.dateCreated)),
              _buildInfoRow("Time:", DateFormat('h:mm a').format(request.dateCreated)),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(5.r)),
                child: Text(request.status, style: TextStyle(color: Colors.yellow.shade800, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10.h),
              const Text("Payment is required to continue processing your request. Please complete your payment to proceed.",
                style: TextStyle(color: Colors.red, fontSize: 11),
              ),
            ]),
            SizedBox(height: 15.h),
            _buildSectionCard("Payment Summary", [
              _buildInfoRow("Document Price:", "PHP 100"),
              _buildInfoRow("Processing Fee:", "PHP 10"),
              const Divider(),
              _buildInfoRow("Total Amount Due:", "PHP 110", isBold: true),
              SizedBox(height: 15.h),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentDetailsScreen(request: request)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF233446)),
                  child: CustomFont(text: "Pay now", color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}