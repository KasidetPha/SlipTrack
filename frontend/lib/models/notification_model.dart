class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['notification_id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['notification_type'] ?? 'general',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}