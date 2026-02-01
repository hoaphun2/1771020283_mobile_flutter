import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Nạp tiền thành công',
      'message': 'Bạn đã nạp 1,000,000 VND vào ví thành công',
      'type': 'success',
      'time': DateTime.now().subtract(const Duration(minutes: 5)),
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'Đặt sân xác nhận',
      'message': 'Đặt sân 1 từ 14:00 - 16:00 ngày mai đã được xác nhận',
      'type': 'info',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': true,
    },
    {
      'id': '3',
      'title': 'Kết quả trận đấu',
      'message': 'Bạn đã thắng trận đấu với đội ABC với tỷ số 2-1',
      'type': 'info',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'Nhắc lịch đấu',
      'message': 'Bạn có lịch đấu vào 15:00 ngày mai tại sân 2',
      'type': 'warning',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n['id'] == id);
      notification['isRead'] = true;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (unreadCount > 0)
            IconButton(
              onPressed: _markAllAsRead,
              icon: Badge(
                label: Text(unreadCount.toString()),
                child: const Icon(Icons.mark_email_read),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isRead = notification['isRead'] as bool;
                
                return Dismissible(
                  key: Key(notification['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteNotification(notification['id']);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: isRead ? Colors.white : Colors.blue[50],
                    child: ListTile(
                      leading: Icon(
                        _getTypeIcon(notification['type']),
                        color: _getTypeColor(notification['type']),
                      ),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification['message']),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm dd/MM/yyyy').format(notification['time']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: !isRead
                          ? IconButton(
                              icon: const Icon(Icons.mark_email_read),
                              onPressed: () => _markAsRead(notification['id']),
                              color: Colors.grey,
                            )
                          : null,
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(notification['id']);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}