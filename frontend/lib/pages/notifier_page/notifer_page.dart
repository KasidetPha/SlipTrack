import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/services/receipt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  return ReceiptService().fetchNotifications();
});

class NotiferPage extends ConsumerWidget {
  const NotiferPage({super.key});

  Future<void> _markAsRead(WidgetRef ref, NotificationItem item) async {
    if (item.isRead) return;

    await ReceiptService().markNotificationAsRead(item.id);
    ref.invalidate(notificationsProvider);
  }

  String _formatTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  (IconData, Color) _getIconForType(String type) {
    switch (type) {
      case 'budget_warning':
        return (Icons.warning_amber_rounded, Colors.orange);

      case 'budget_exceeded':
        return (Icons.error_rounded, Colors.red);

      case 'receipt':
        return (Icons.receipt_long_rounded, const Color(0xFF5046E8));

      case 'analytics':
        return (Icons.analytics_rounded, Colors.blue);

      default:
        return (Icons.notifications_rounded, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = const Color(0xFFFAFAFA);
    final notificationsAsync = ref.watch(notificationsProvider);

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
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            "โหลดการแจ้งเตือนไม่สำเร็จ",
            style: GoogleFonts.prompt(color: Colors.grey),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                "ไม่มีการแจ้งเตือนใหม่",
                style: GoogleFonts.prompt(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final iconData = _getIconForType(item.type);

                return GestureDetector(
                  onTap: () => _markAsRead(ref, item),
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
          ),
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
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.prompt(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w500,
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