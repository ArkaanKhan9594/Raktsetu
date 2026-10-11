import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/app_state.dart';
import '../../models/blood_event.dart';
import '../../widgets/event_card.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadAll());
  }

  List<BloodEvent> _filter(List<BloodEvent> all, EventStatus status) =>
      all.where((e) => e.status == status).toList()
        ..sort((a, b) => status == EventStatus.past
            ? b.startDateTime.compareTo(a.startDateTime)
            : a.startDateTime.compareTo(b.startDateTime));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<BloodEvent> _eventsOnDay(List<BloodEvent> all, DateTime day) =>
      all.where((e) => _isSameDay(e.startDateTime, day)).toList();

  Color _dotColorFor(BloodEvent e) => switch (e.status) {
        EventStatus.upcoming => const Color(0xFF1B3A6B),
        EventStatus.ongoing => const Color(0xFF2E7D32),
        EventStatus.past => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Donation Events'),
          actions: [
            IconButton(
              tooltip: _showCalendar ? 'Switch to list view' : 'Switch to calendar view',
              icon: Icon(_showCalendar ? Icons.view_list : Icons.calendar_month),
              onPressed: () => setState(() => _showCalendar = !_showCalendar),
            ),
          ],
          bottom: _showCalendar
              ? null
              : const TabBar(tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Live'),
                  Tab(text: 'Past'),
                ]),
        ),
        body: Consumer<AppState>(
          builder: (context, appState, _) {
            if (appState.isLoading) return const Center(child: CircularProgressIndicator());

            if (_showCalendar) {
              final dayEvents = _eventsOnDay(appState.events, _selectedDay);
              return Column(
                children: [
                  TableCalendar<BloodEvent>(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 730)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
                    eventLoader: (day) => _eventsOnDay(appState.events, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Color(0xFF1B3A6B), shape: BoxShape.circle),
                      selectedDecoration: BoxDecoration(color: Color(0xFFB3122E), shape: BoxShape.circle),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        return Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: events.take(3).map((e) {
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(color: _dotColorFor(e), shape: BoxShape.circle),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: dayEvents.isEmpty
                        ? const Center(child: Text('No events on this day.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: dayEvents.length,
                            itemBuilder: (_, i) => EventCard(
                              event: dayEvents[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EventDetailScreen(event: dayEvents[i])),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            }

            final upcoming = _filter(appState.events, EventStatus.upcoming);
            final ongoing = _filter(appState.events, EventStatus.ongoing);
            final past = _filter(appState.events, EventStatus.past);

            Widget list(List<BloodEvent> events) {
              if (events.isEmpty) {
                return const Center(child: Text('No events here yet.'));
              }
              return RefreshIndicator(
                onRefresh: appState.loadAll,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (_, i) => EventCard(
                    event: events[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EventDetailScreen(event: events[i])),
                    ),
                  ),
                ),
              );
            }

            return TabBarView(children: [list(upcoming), list(ongoing), list(past)]);
          },
        ),
      ),
    );
  }
}
