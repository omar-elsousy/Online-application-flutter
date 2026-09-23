import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/app_notification.dart';
import '../utils/search_utils.dart';
import '../widgets/app_search_field.dart';
import 'notification_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => AppScope.of(context).loadNotifications();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final notifications = state.notifications
        .where(
          (notification) => matchesSearchQuery(_query, [
            notification.id,
            notification.title,
            notification.body,
            notification.createdAt,
          ]),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (state.unreadNotificationsCount > 0)
            TextButton(
              onPressed: state.markAllNotificationsAsRead,
              child: const Text('قراءة الكل'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: AppSearchField(
              value: _query,
              onChanged: (value) => setState(() => _query = value),
              hintText: 'ابحث في الإشعارات',
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: notifications.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 180),
                        const Icon(
                          Icons.notifications_none,
                          size: 56,
                          color: Colors.black38,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _query.isEmpty
                                ? 'لا توجد إشعارات حتى الآن'
                                : 'لا توجد إشعارات مطابقة للبحث',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _NotificationTile(
                        notification: notifications[index],
                        onTap: () async {
                          final notification = notifications[index];
                          await state.markNotificationAsRead(notification);
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationDetailsScreen(
                                notification: notification,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final date = notification.createdAt;
    final timestamp = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      color: notification.isRead ? Colors.white : color.withValues(alpha: 0.08),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(
            alpha: notification.isRead ? 0.12 : 0.2,
          ),
          child: Icon(Icons.notifications, color: color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body.isNotEmpty) ...[
              Text(notification.body),
              const SizedBox(height: 6),
            ],
            if (timestamp.isNotEmpty)
              Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Icon(Icons.circle, size: 10, color: color),
      ),
    );
  }
}
