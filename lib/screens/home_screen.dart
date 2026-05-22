import 'package:capstone_project/screens/data_consent_screen.dart';
import 'package:capstone_project/screens/pending_screen.dart';
import 'package:capstone_project/screens/profile_screen.dart';
import 'package:capstone_project/screens/history_screen.dart';
import 'package:capstone_project/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/notification_item.dart';
import '../services/mongo_data_api_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  final PendingRequest? newRequest;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.newRequest,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late PageController _pageController;
  late List<NotificationItem> _notifications;
  List<PendingRequest> _pendingRequests = [];
  List<HistoryItem> _historyItems = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _notifications = [
      NotificationItem(
        title: 'Document ready',
        message: 'Your requested document is ready for pickup.',
        timestamp: 'Just now',
      ),
      NotificationItem(
        title: 'Request received',
        message: 'We have received your request and are processing it.',
        timestamp: '2h ago',
        isRead: true,
      ),
      NotificationItem(
        title: 'Profile updated',
        message: 'Your profile details were updated successfully.',
        timestamp: 'Yesterday',
      ),
    ];

    _loadRequests();
  }

  bool _isCompletedStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'completed';
  }

  bool _isApprovedStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'approved' ||
        normalized == 'released' ||
        normalized == 'completed';
  }

  String _displayStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return 'PENDING FOR PAYMENT';
    if (normalized == 'pending_payment' || normalized == 'pending for payment') {
      return 'PENDING FOR PAYMENT';
    }
    if (normalized == 'pending_completion' || normalized == 'pending to complete') {
      return 'PENDING TO COMPLETE';
    }
    return normalized.toUpperCase();
  }

  DateTime _parseRequestDate(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  void _mergeNewRequest(List<PendingRequest> pending) {
    final newRequest = widget.newRequest;
    if (newRequest == null) return;

    final exists = pending.any((item) {
      final timeDiff = item.dateCreated
          .difference(newRequest.dateCreated)
          .inMinutes
          .abs();
      return item.docName == newRequest.docName &&
          item.purpose == newRequest.purpose &&
          timeDiff < 1;
    });

    if (!exists && !_isCompletedStatus(newRequest.status)) {
      pending.insert(0, newRequest);
    }
  }

  Future<void> _loadRequests() async {
    if (_isLoadingRequests) return;
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final items = await MongoDataApiService.instance.fetchRequests();
      final pending = <PendingRequest>[];
      final history = <HistoryItem>[];

      for (final item in items) {
        final docName = item['docName']?.toString().trim() ?? '';
        if (docName.isEmpty) continue;
        final purpose = item['purpose']?.toString().trim() ?? '';
        final statusRaw = item['status']?.toString().trim() ?? 'pending';
        final createdAt = _parseRequestDate(item['createdAt']);
        final status = _displayStatus(statusRaw);

        if (_isCompletedStatus(statusRaw)) {
          history.add(HistoryItem(
            title: docName,
            date: createdAt,
            purpose: purpose,
            status: status,
            isApproved: _isApprovedStatus(statusRaw),
          ));
        } else {
          pending.add(PendingRequest(
            docName: docName,
            purpose: purpose,
            dateCreated: createdAt,
            status: status,
          ));
        }
      }

      _mergeNewRequest(pending);

      if (!mounted) return;
      setState(() {
        _pendingRequests = pending;
        _historyItems = history;
        _isLoadingRequests = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  int get _unreadCount =>
      _notifications.where((item) => !item.isRead).length;

  void _openNotifications() {
    setState(() {
      for (final item in _notifications) {
        item.isRead = true;
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationScreen(notifications: _notifications),
      ),
    );
  }


  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.animateToPage(
      value,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (value == 1 || value == 2) {
      _loadRequests();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _selectedIndex = page;
          });
          if (page == 1 || page == 2) {
            _loadRequests();
          }
        },
        children: [
          _buildHomeContent(context),
          PendingScreen(
            requestList: _isLoadingRequests ? [] : _pendingRequests,
          ),
          HistoryScreen(
            historyList: _isLoadingRequests ? [] : _historyItems,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildNavigationItem(Icons.home_outlined, Icons.home, 0)),
            Expanded(child: _buildNavigationItem(Icons.access_time, Icons.access_time_filled, 1)),
            Expanded(child: _buildNavigationItem(Icons.assignment_outlined, Icons.assignment, 2)),
          ],
        ),
      ),
    );
  }

  
  Widget _buildNavigationItem(IconData icon, IconData activeIcon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTappedBar(index),
      child: Container(
        alignment: Alignment.center,
        height: 80.h,
        decoration: BoxDecoration(
          color: isSelected ? FB_PRIMARY : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : FB_DARK_PRIMARY,
          size: 28.sp,
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none, // Allows the card to overlap the header
            children: [
              // Top Section: Header with Welcome Text
              Container(
                height: 220.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FB_PRIMARY,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30.r),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _openNotifications,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 20.r,
                                    child: Icon(
                                      Icons.notifications,
                                      size: 22.sp,
                                      color: FB_PRIMARY,
                                    ),
                                  ),
                                  if (_unreadCount > 0)
                                    Positioned(
                                      right: -4.w,
                                      top: -4.h,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          _unreadCount > 99
                                              ? '99+'
                                              : _unreadCount.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20.r,
                                child: Icon(
                                  Icons.person,
                                  size: 22.sp,
                                  color: FB_PRIMARY,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "Welcome to VerifiTOR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\u201cInnovation in Every Credentials\u201d",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),

          // Spacing between header and content
          SizedBox(height: 12.h),

          // REQUEST BUTTON
          Padding(
            padding: EdgeInsets.only(bottom: 30.h),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2E3C), // Dark Navy from image
                padding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 15.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                elevation: 5,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataConsentScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "REQUEST",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 24.sp),
                ],
              ),
            ),
          ),

          // Document Price List Section (Carousel)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Document Requests Price List",
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 300.h, // Height for your table image
                    child: PageView(
                      controller: PageController(viewportFraction: 0.9),
                      children: [
                        _buildCarouselImage('assets/image/docs_prices.png'),
                        _buildCarouselImage('assets/image/codelectives.jpg'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildCarouselImage(String path) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}