import 'donor.dart';

enum UrgencyLevel { normal, urgent, critical }

extension UrgencyLabel on UrgencyLevel {
  String get label => switch (this) {
        UrgencyLevel.normal => 'Normal',
        UrgencyLevel.urgent => 'Urgent',
        UrgencyLevel.critical => 'Critical',
      };
}

enum RequestStatus { open, partiallyFulfilled, fulfilled, closed }

class BloodRequest {
  final String id;
  final String requesterName;
  final String requesterPhone;
  final String? patientName;
  final String? medicalReason;
  final BloodGroup bloodGroup;
  final int unitsNeeded;
  final String hospital;
  final String city;
  final UrgencyLevel urgency;
  final DateTime createdAt;
  RequestStatus status;
  final List<String> matchedDonorIds;
  final double? latitude;
  final double? longitude;

  BloodRequest({
    required this.id,
    required this.requesterName,
    required this.requesterPhone,
    this.patientName,
    this.medicalReason,
    required this.bloodGroup,
    required this.unitsNeeded,
    required this.hospital,
    required this.city,
    required this.urgency,
    required this.createdAt,
    this.status = RequestStatus.open,
    List<String>? matchedDonorIds,
    this.latitude,
    this.longitude,
  }) : matchedDonorIds = matchedDonorIds ?? [];

  bool get hasLocation => latitude != null && longitude != null;

  String get effectivePatientName =>
      (patientName != null && patientName!.trim().isNotEmpty) ? patientName!.trim() : requesterName;
}
