import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/blood_event.dart';
import '../../providers/app_state.dart';

class EventDetailScreen extends StatelessWidget {
  final BloodEvent event;
  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE, d MMMM yyyy · h:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Consumer<AppState>(builder: (context, appState, _) {
        final donor = appState.currentDonor;
        final alreadyRegistered = donor != null && event.registeredDonorIds.contains(donor.id);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Organized by ${event.organizer}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              _infoRow(Icons.calendar_today, df.format(event.startDateTime)),
              _infoRow(Icons.location_on, event.venue),
              _infoRow(Icons.people, '${event.registeredDonorIds.length} / ${event.capacity} registered'),
              const Spacer(),
              if (alreadyRegistered)
                _banner('You are registered for this event.', Colors.green)
              else if (donor != null && donor.isUnder18)
                _banner('Underage (${donor.age} yrs): Blood donation requires a minimum age of 18 years by law.', const Color(0xFFB3122E))
              else if (donor != null && donor.isOverAge)
                _banner('Upper Age Limit Exceeded (${donor.age} yrs): Voluntary blood donation is safe between 18 and 65 years.', const Color(0xFFB3122E))
              else if (donor != null && donor.eligibleFromDate != null && donor.eligibleFromDate!.isAfter(event.startDateTime))
                _banner('You will still be in your 90-day recovery rest window on this camp date (Next eligible: ${DateFormat('d MMM yyyy').format(donor.eligibleFromDate!)}).', Colors.orange.shade800)
              else if (event.isFull)
                _banner('This event is fully booked.', Colors.orange)
              else if (event.status != EventStatus.upcoming)
                _banner('Registration closed for this event.', Colors.grey)
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: donor == null
                        ? null
                        : () async {
                            try {
                              await appState.registerForEvent(event.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registered successfully!')),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
                    child: const Text('Register for this Event', style: TextStyle(color: Colors.white)),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ]),
      );

  Widget _banner(String text, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );
}
