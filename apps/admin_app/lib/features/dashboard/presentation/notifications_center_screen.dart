import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'notifications_notifier.dart';

class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  ConsumerState<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends ConsumerState<NotificationsCenterScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    var filtered = state.notifications;
    if (_selectedFilter == 'unread') {
      filtered = state.notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'read') {
      filtered = state.notifications.where((n) => n.isRead).toList();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ops Notifications Center',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review live booking creations, status logs updates, and critical system alarms.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                // Filters
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All Alerts'),
                      selected: _selectedFilter == 'all',
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Unread'),
                      selected: _selectedFilter == 'unread',
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = 'unread');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Read'),
                      selected: _selectedFilter == 'read',
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = 'read');
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live event listener indicator banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_checked_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Listening to booking events real-time. Socket.IO connection active.',
                    style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification cards list
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('No notifications fit the selected filters.'),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final notification = filtered[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: notification.isRead ? Colors.transparent : AppTheme.primaryTeal.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: notification.isRead ? Colors.grey.shade100 : Colors.teal.shade50,
                                  child: Icon(
                                    notification.title.contains('🚨') ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                    color: notification.isRead ? Colors.grey : AppTheme.primaryTeal,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(notification.message),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!notification.isRead)
                                      IconButton(
                                        icon: const Icon(Icons.check_rounded, color: Colors.green),
                                        onPressed: () => ref.read(notificationsProvider.notifier).markRead(notification.id),
                                        tooltip: 'Mark as read',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                      onPressed: () => ref.read(notificationsProvider.notifier).deleteNotification(notification.id),
                                      tooltip: 'Delete alert',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
