import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      10,
      (i) => _NotificationItem(
        title: i.isEven ? 'Price drop on your saved listing' : 'New listing near you',
        message: i.isEven ? 'A property you favorited dropped 5% (mock).' : 'Fresh rental listings added in your area (mock).',
        time: '${i + 1}h ago',
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = items[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.notifications_rounded, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(n.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            subtitle: Text(n.message),
            trailing: Text(n.time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).hintColor)),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  const _NotificationItem({required this.title, required this.message, required this.time});
}
