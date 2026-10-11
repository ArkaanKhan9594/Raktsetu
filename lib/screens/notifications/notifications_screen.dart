import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../providers/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType t) => switch (t) {
        NotificationType.matchFound => Icons.bloodtype,
        NotificationType.requestStatusChanged => Icons.info_outline,
        NotificationType.donationVerified => Icons.verified,
        NotificationType.eventRegistration => Icons.event_available,
        NotificationType.referralJoined => Icons.person_add_alt_1,
      };

  Color _colorFor(NotificationType t) => switch (t) {
        NotificationType.matchFound => const Color(0xFFB3122E),
        NotificationType.requestStatusChanged => const Color(0xFF1B3A6B),
        NotificationType.donationVerified => const Color(0xFF2E7D32),
        NotificationType.eventRegistration => const Color(0xFFB07000),
        NotificationType.referralJoined => const Color(0xFF7C4DFF),
      };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Consumer<AppState>(builder: (context, appState, _) {
        final items = appState.notifications;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No notifications yet. You\'ll see updates here about matched requests, '
                  'event registrations, and verified donations.', textAlign: TextAlign.center),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final n = items[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: n.isRead ? null : _colorFor(n.type).withValues(alpha: 0.06),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorFor(n.type).withValues(alpha: 0.15),
                  child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 20),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(n.body, style: const TextStyle(fontSize: 13)),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_relativeTime(n.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (!n.isRead)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _colorFor(n.type), shape: BoxShape.circle),
                      ),
                  ],
                ),
                onTap: () {
                  if (!n.isRead) context.read<AppState>().markNotificationRead(n.id);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
