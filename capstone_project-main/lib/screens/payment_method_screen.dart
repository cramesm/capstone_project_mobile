import 'package:capstone_project/screens/history_screen.dart';
import 'package:capstone_project/screens/home_screen.dart';
import 'package:capstone_project/screens/pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../widgets/custom_font.dart';
import '../screens/request_detail_screen.dart';
import '../screens/request_form_screen.dart';


class PaymentMethodScreen extends StatefulWidget {
  final PendingRequest request;
  const PaymentMethodScreen({super.key, required this.request});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D7E97),
        title: CustomFont(text: "Payment Method", color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
           Container(
              child: Column(
                children: [
              _buildSectionCard("Billing Summary", [
              _infoRow("Document Requested", widget.request.docName),
              _infoRow("Processing Fee", "PHP 10.00"),
              _infoRow("Document Price", "PHP 100.00"),
              const Divider(),
              _infoRow("Total Amount Due", "PHP 110.00", isBold: true),
            ]),
                ],
              ),
           ),
            


            SizedBox(height: 20.h),
            // Payment Provider Selection
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomFont(text: "Payment Method", fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF233446)),
                  SizedBox(height: 15.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.blue.shade200)),
                    child: Row(
                      children: [
                        CustomFont(text: "E-wallet", fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.blue.shade700),
                        const Spacer(),
                        const Icon(Icons.account_balance_wallet, color: Colors.blue),
                        SizedBox(width: 8.w),
                        CustomFont(text: "GCash", fontWeight: FontWeight.bold, color: Colors.blue.shade700, fontSize: 14.sp),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  CustomFont(text: "You will be redirected to the secure GCash payment page.", fontSize: 10.sp, color: Colors.black54),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Checkbox(value: _acknowledged, activeColor: const Color(0xFF5D7E97), onChanged: (val) => setState(() => _acknowledged = val!)),
                Expanded(child: CustomFont(text: "I acknowledge that I will be redirected to complete the transaction.", fontSize: 10.sp, color: Colors.black54)),
              ],
            ),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: _acknowledged 
                ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => SuccessfulScreen(request: widget.request)))
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF233446),
                fixedSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: CustomFont(text: "Confirm Payment", color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFont(text: title, fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF233446)),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

   Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomFont(text: label, fontSize: 13.sp, color: Colors.black54),
          CustomFont(text: value, fontSize: 13.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? const Color(0xFF233446) : Colors.black87),
        ],
      ),
    );
  }


  Widget _miniRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomFont(text: label, fontSize: 12.sp, color: Colors.black54),
          CustomFont(text: value, fontSize: 12.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFF233446) : Colors.black87),
        ],
      ),
    );
  }
}


class SuccessfulScreen extends StatelessWidget {
  final PendingRequest request;

  const SuccessfulScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 120.r, width: 120.r,
                decoration: const BoxDecoration(color: Color(0xFF9DB2BF), shape: BoxShape.circle),
                child: Icon(Icons.check, color: Colors.white, size: 80.r),
              ),
              SizedBox(height: 30.h),
              CustomFont(text: "Payment Successful", fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF233446)),
              SizedBox(height: 10.h),
              CustomFont(
                text: "Your payment has been successfully submitted. Please wait while the registrar verifies your payment.",
                textAlign: TextAlign.center, fontSize: 13.sp, color: Colors.black54,
              ),
              SizedBox(height: 50.h),
              ElevatedButton(
                onPressed: () {
                  // Need to improve logic for updating the request status in the actual app, but for now we will just navigate back to home with the new request added to pending list
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        initialIndex: 1, // Go to Pending/Requests Tab
                        newRequest: PendingRequest(
                          docName: request.docName,
                          purpose: request.purpose,
                          dateCreated: request.dateCreated,
                          status: "Processing", // Updated status
                        ),
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27374D),
                  fixedSize: Size(340.w, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: CustomFont(text: "Proceed", fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}