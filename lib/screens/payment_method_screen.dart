import 'dart:typed_data';

import 'package:capstone_project/screens/home_screen.dart';
import 'package:capstone_project/screens/pending_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mongo_data_api_service.dart';
import '../widgets/custom_font.dart';


class PaymentMethodScreen extends StatefulWidget {
  final PendingRequest request;
  const PaymentMethodScreen({super.key, required this.request});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _acknowledged = false;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _onSiteReceiptBytes;
  String? _onSiteReceiptName;
  Uint8List? _gcashReceiptBytes;
  String? _gcashReceiptName;

  bool get _hasReceipt =>
      _onSiteReceiptBytes != null || _gcashReceiptBytes != null;

  Future<void> _pickReceipt({required bool isGcash}) async {
    final source = isGcash ? ImageSource.gallery : ImageSource.camera;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      if (isGcash) {
        _gcashReceiptBytes = bytes;
        _gcashReceiptName = file.name;
      } else {
        _onSiteReceiptBytes = bytes;
        _onSiteReceiptName = file.name;
      }
    });
  }

  Future<void> _submitPayment() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = MongoDataApiService.instance;
      if (_onSiteReceiptBytes != null) {
        await service.uploadReceipt(
          bytes: _onSiteReceiptBytes!,
          fileName: _onSiteReceiptName ?? 'onsite-receipt.jpg',
          paymentType: 'onsite',
          docName: widget.request.docName,
          purpose: widget.request.purpose,
        );
      }
      if (_gcashReceiptBytes != null) {
        await service.uploadReceipt(
          bytes: _gcashReceiptBytes!,
          fileName: _gcashReceiptName ?? 'gcash-receipt.jpg',
          paymentType: 'gcash',
          docName: widget.request.docName,
          purpose: widget.request.purpose,
        );
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessfulScreen(request: widget.request),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Upload failed: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

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
            // Receipt Upload
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomFont(text: "Upload Receipt", fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF233446)),
                  SizedBox(height: 12.h),
                  _buildReceiptSection(
                    title: "Paid on site",
                    description: "Upload a photo of the official receipt.",
                    buttonLabel: "Take photo",
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickReceipt(isGcash: false),
                    previewBytes: _onSiteReceiptBytes,
                    fileName: _onSiteReceiptName,
                  ),
                  SizedBox(height: 12.h),
                  _buildReceiptSection(
                    title: "GCash payment",
                    description: "Upload a screenshot of the receipt.",
                    buttonLabel: "Upload screenshot",
                    onPressed: _isSubmitting
                        ? null
                        : () => _pickReceipt(isGcash: true),
                    previewBytes: _gcashReceiptBytes,
                    fileName: _gcashReceiptName,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Checkbox(value: _acknowledged, activeColor: const Color(0xFF5D7E97), onChanged: (val) => setState(() => _acknowledged = val!)),
                Expanded(child: CustomFont(text: "I acknowledge that I will upload the required payment receipt.", fontSize: 10.sp, color: Colors.black54)),
              ],
            ),
            if (!_hasReceipt)
              Padding(
                padding: EdgeInsets.only(left: 8.w, bottom: 6.h),
                child: CustomFont(
                  text: "Upload at least one receipt to continue.",
                  fontSize: 10.sp,
                  color: Colors.redAccent,
                ),
              ),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: _acknowledged && _hasReceipt && !_isSubmitting
                ? _submitPayment
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF233446),
                fixedSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : CustomFont(text: "Confirm Payment", color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
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

  Widget _buildReceiptSection({
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback? onPressed,
    Uint8List? previewBytes,
    String? fileName,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFont(text: title, fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF233446)),
          SizedBox(height: 4.h),
          CustomFont(text: description, fontSize: 11.sp, color: Colors.black54),
          SizedBox(height: 8.h),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.upload_file),
            label: Text(buttonLabel),
          ),
          if (previewBytes != null) ...[
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.memory(
                previewBytes,
                height: 140.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (fileName != null && fileName.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            CustomFont(text: fileName, fontSize: 10.sp, color: Colors.black54),
          ],
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