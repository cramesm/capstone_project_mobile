class NotificationItem {
  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  final String title;
  final String message;
  final String timestamp;
  bool isRead;
}
