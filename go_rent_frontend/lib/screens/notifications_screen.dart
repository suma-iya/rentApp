import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/notification.dart' as models;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<models.AppNotification> _notifications = [];
  bool _hasMarkedAsRead = false;

  final Map<int, TextEditingController> _commentControllers = {};
  final Map<int, bool> _showCommentInput = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Mark notifications as read when app goes to background or is paused
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _markNotificationsAsRead();
    }
  }

  Future<void> _markNotificationsAsRead() async {
    if (!_hasMarkedAsRead) {
      try {
        await _apiService.markNotificationsAsRead();
        _hasMarkedAsRead = true;
        print('Notifications marked as read when leaving screen');
      } catch (e) {
        print('Error marking notifications as read: $e');
      }
    }
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
            content: Text('Notification ${accept ? 'accepted' : 'rejected'} successfully.'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
        await _loadNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process the action.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendComment(models.AppNotification notification) async {
    final comment = _commentControllers[notification.id]?.text.trim();
    if (comment == null || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final success = await _apiService.sendComment(notification.id, comment);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment sent successfully'), backgroundColor: Colors.green),
        );

        setState(() {
          _showCommentInput[notification.id] = false;
          _commentControllers[notification.id]?.dispose();
          _commentControllers.remove(notification.id);
        });

      await _loadNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send comment'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    return WillPopScope(
      onWillPop: () async {
        // Mark notifications as read when user navigates back
        await _markNotificationsAsRead();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF2196F3),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              // Mark notifications as read when user presses back button
              await _markNotificationsAsRead();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadNotifications,
            ),
          ],
      ),
      body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                        onPressed: _loadNotifications,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ll see your notifications here',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                        color: const Color(0xFF2196F3),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (index * 100)),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: _buildNotificationCard(notification),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildNotificationCard(models.AppNotification notification) {
    Color statusColor = Colors.orange;
    if (notification.status == 'accepted') statusColor = Colors.green;
    else if (notification.status == 'rejected') statusColor = Colors.red;

    return Container(
      decoration: BoxDecoration(
        gradient: notification.isRead
            ? LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: notification.isRead 
                ? Colors.black.withOpacity(0.05)
                : const Color(0xFF2196F3).withOpacity(0.1),
            blurRadius: notification.isRead ? 8 : 12,
            offset: const Offset(0, 4),
            spreadRadius: notification.isRead ? 0 : 2,
          ),
        ],
        border: notification.isRead 
            ? null 
            : Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                width: 1.5,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _markNotificationsAsRead(),
                            child: Padding(
            padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                // Header with unread indicator and status
                Row(
                  children: [
                    if (!notification.isRead)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: notification.isRead ? Colors.grey.shade700 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info rows
                _buildInfoRow(Icons.home, notification.property.name, isRead: notification.isRead),
                _buildInfoRow(Icons.apartment, notification.floor.name, isRead: notification.isRead),
                _buildInfoRow(Icons.info_outline, 'Status: ${notification.status}', color: statusColor, isRead: notification.isRead),
                _buildInfoRow(Icons.calendar_today_outlined, _formatDate(notification.createdAt), isRead: notification.isRead),

                // Comment section
                if (notification.comment != null && notification.comment!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: notification.isRead 
                            ? [Colors.grey.shade100, Colors.grey.shade200]
                            : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: notification.isRead 
                            ? Colors.grey.shade300
                            : Color.fromARGB(255, 228, 233, 236).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                        Icon(
                          Icons.reply,
                          size: 20,
                          color: notification.isRead ? Colors.grey.shade600 : const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notification.comment!,
                            style: TextStyle(
                              color: notification.isRead ? Colors.grey.shade700 : Colors.black87,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                                        ],
                                      ),
                                    ),
                ],

                // Comment input section
                if (_showCommentInput[notification.id] == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                                        children: [
                        TextField(
                          controller: _commentControllers[notification.id],
                          decoration: InputDecoration(
                            labelText: 'Add your comment...',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14),
                                    ),
                                  Padding(
                          padding: const EdgeInsets.all(12),
                                    child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showCommentInput[notification.id] = false;
                                    _commentControllers[notification.id]?.dispose();
                                    _commentControllers.remove(notification.id);
                                  });
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _sendComment(notification),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Send'),
                              ),
                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                ],

                // Action buttons
                if (notification.status == 'pending' && notification.showActions || 
                    (notification.comment == null || notification.comment!.isEmpty) &&
                    !(notification.status == 'pending' && notification.showActions) &&
                    _showCommentInput[notification.id] != true) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                                    children: [
                                      if (notification.status == 'pending' && notification.showActions) ...[
                        _buildActionButton(
                          Icons.check_circle,
                          'Accept',
                          const Color(0xFF4CAF50),
                          () => _handleNotificationAction(notification, true),
                        ),
                        _buildActionButton(
                          Icons.cancel,
                          'Reject',
                          const Color(0xFFF44336),
                          () => _handleNotificationAction(notification, false),
                        ),
                      ],
                      if ((notification.comment == null || notification.comment!.isEmpty) &&
                          !(notification.status == 'pending' && notification.showActions) &&
                          _showCommentInput[notification.id] != true)
                        _buildActionButton(
                          Icons.comment,
                          'Add Comment',
                          const Color(0xFF2196F3),
                          () {
                            setState(() {
                              _showCommentInput[notification.id] = true;
                              _commentControllers[notification.id] = TextEditingController();
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isRead = false, Color? color}) {
    // Special handling for status rows to always show in color
    bool isStatusRow = text.startsWith('Status:');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isRead ? Colors.grey.shade200 : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isRead ? Colors.grey.shade600 : const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isStatusRow 
                    ? (color ?? Colors.black87) // Always use color for status
                    : (isRead ? Colors.grey.shade600 : (color ?? Colors.black87)), // Normal read/unread logic for others
                fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                              ),
                            ),
              ],
            ),
          ),
                      ),
                    ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'accepted':
        return [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
      case 'rejected':
        return [const Color(0xFFF44336), const Color(0xFFEF5350)];
      case 'pending':
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
      default:
        return [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)];
    }
  }
}
