import 'package:flutter/material.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotiferPage extends StatefulWidget {
  const NotiferPage({super.key});

  @override
  State<NotiferPage> createState() => _NotiferPageState();
}

class _NotiferPageState extends State<NotiferPage> {
  
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ReceiptService().fetchNotifications();
      setState(() => _notifications = data);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMarkAsRead(NotificationItem item) async {
    if (item.isRead) return; 

    setState(() {
      item.isRead = true; 
    });
    
    try {
      await ReceiptService().markNotificationAsRead(item.id);
    } catch (e) {
      print("Error update read status: $e");
    }
  }

  // ฟังก์ชันแปลงวันที่ให้สวยงาม
  String _formatTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // ฟังก์ชันเลือก Icon ตามประเภทการแจ้งเตือน
  (IconData, Color) _getIconForType(String type) {
    switch (type) {
      case 'warning': return (Icons.warning_amber_rounded, Colors.orange);
      case 'receipt': return (Icons.receipt_long_rounded, const Color(0xFF5046E8));
      case 'analytics': return (Icons.analytics_rounded, Colors.blue);
      default: return (Icons.notifications_rounded, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "การแจ้งเตือน",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty 
          ? Center(
              child: Text(
                "ไม่มีการแจ้งเตือนใหม่", 
                style: GoogleFonts.prompt(color: Colors.grey)
              )
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                final iconData = _getIconForType(item.type);

                return GestureDetector(
                  onTap: () => _handleMarkAsRead(item),
                  child: _buildNotificationCard(
                    title: item.title,
                    body: item.body,
                    time: _formatTime(item.createdAt),
                    icon: iconData.$1,
                    iconColor: iconData.$2,
                    isUnread: !item.isRead,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.prompt(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                          fontSize: 15,
                          color: const Color(0xFF1E1E1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5046E8),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.prompt(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}