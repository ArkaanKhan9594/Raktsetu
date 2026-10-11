enum EventStatus { past, ongoing, upcoming }

class BloodEvent {
  final String id;
  final String title;
  final String organizer;
  final String venue;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int capacity;
  final List<String> registeredDonorIds;
  final double? latitude;
  final double? longitude;

  BloodEvent({
    required this.id,
    required this.title,
    required this.organizer,
    required this.venue,
    required this.startDateTime,
    required this.endDateTime,
    required this.capacity,
    List<String>? registeredDonorIds,
    this.latitude,
    this.longitude,
  }) : registeredDonorIds = registeredDonorIds ?? [];

  bool get hasLocation => latitude != null && longitude != null;

  EventStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDateTime)) return EventStatus.upcoming;
    if (now.isAfter(endDateTime)) return EventStatus.past;
    return EventStatus.ongoing;
  }

  int get seatsLeft => capacity - registeredDonorIds.length;
  bool get isFull => seatsLeft <= 0;
}
