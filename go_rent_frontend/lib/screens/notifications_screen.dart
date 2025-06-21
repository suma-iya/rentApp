import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/notification.dart' as models;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<models.AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _apiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleNotificationAction(models.AppNotification notification, bool accept) async {
    try {
      if (notification.status != 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification is no longer pending (status: ${notification.status})')),
        );
        return;
      }

      final success = await _apiService.handleTenantRequestAction(notification.id, accept);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification ${accept ? 'accepted' : 'rejected'} successfully'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
        await _loadNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${accept ? 'accept' : 'reject'} notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];

                          Color statusColor;
                          switch (notification.status) {
                            case 'accepted':
                              statusColor = Colors.green;
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.orange;
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.message,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!notification.message.contains(notification.property.name))
                                    Row(
                                      children: [
                                        const Icon(Icons.home, size: 20, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(notification.property.name),
                                      ],
                                    ),
                                  if (notification.floor.name.isNotEmpty &&
                                      !notification.message.contains(notification.floor.name))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.apartment, size: 20, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(notification.floor.name),
                                        ],
                                      ),
                                    ),
                                  if (!notification.message.contains(notification.createdAt.split('T')[0]))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(_formatDate(notification.createdAt)),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Status: ${notification.status}',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (notification.status == 'pending' && notification.showActions) ...[
                                        TextButton.icon(
                                          onPressed: () => _handleNotificationAction(notification, true),
                                          icon: const Icon(Icons.check, color: Colors.green),
                                          label: const Text('Accept'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _handleNotificationAction(notification, false),
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          label: const Text('Reject'),
                                        ),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                        onPressed: () => _deleteNotification(notification.id),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
