import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/blood_event.dart';

class EventCard extends StatelessWidget {
  final BloodEvent event;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap});

  Color get _statusColor => switch (event.status) {
        EventStatus.upcoming => const Color(0xFF1B3A6B),
        EventStatus.ongoing => const Color(0xFF2E7D32),
        EventStatus.past => Colors.grey,
      };

  String get _statusLabel => switch (event.status) {
        EventStatus.upcoming => 'UPCOMING',
        EventStatus.ongoing => 'LIVE NOW',
        EventStatus.past => 'PAST',
      };

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, d MMM yyyy · h:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  if (!event.isFull)
                    Text('${event.seatsLeft} seats left',
                        style: const TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    const Text('Full', style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(event.organizer, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(child: Text(event.venue, style: const TextStyle(fontSize: 13))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(df.format(event.startDateTime), style: const TextStyle(fontSize: 13)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
