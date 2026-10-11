import 'package:uuid/uuid.dart';
import '../models/donor.dart';
import '../models/blood_event.dart';
import '../models/blood_request.dart';
import '../models/donation_record.dart';
import '../models/donor_match.dart';
import '../models/app_notification.dart';
import '../utils/blood_compatibility.dart';
import '../utils/geo.dart';
import 'api_client.dart';
import 'data_repository.dart';

const _uuid = Uuid();

class RestDataRepository implements DataRepository {
  final ApiClient apiClient;

  // Local cache for offline resilience and fast navigation
  final List<Donor> _cachedDonors = [];
  final List<BloodEvent> _cachedEvents = [];
  final List<BloodRequest> _cachedRequests = [];

  RestDataRepository({required this.apiClient});

  // --- JSON Serialization Helpers ---
  Donor _donorFromJson(Map<String, dynamic> j) {
    return Donor(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      phone: j['phone'] ?? '',
      bloodGroup: BloodGroup.values.firstWhere(
        (e) => e.name == j['blood_group'] || e.label == j['blood_group'],
        orElse: () => BloodGroup.oPos,
      ),
      city: j['city'] ?? '',
      dob: j['dob'] != null ? DateTime.parse(j['dob'].toString()) : DateTime(2000, 1, 1),
      gender: j['gender'] ?? 'Male',
      lastDonationDate: j['last_donation_date'] != null ? DateTime.parse(j['last_donation_date'].toString()) : null,
      isVerified: j['is_verified'] == true,
      isAdmin: j['is_admin'] == true,
      latitude: j['latitude'] != null ? (j['latitude'] as num).toDouble() : null,
      longitude: j['longitude'] != null ? (j['longitude'] as num).toDouble() : null,
      referralCode: j['referral_code'],
      referredByCode: j['referred_by_code'],
    );
  }

  Map<String, dynamic> _donorToJson(Donor d) => {
        'id': d.id,
        'name': d.name,
        'phone': d.phone,
        'bloodGroup': d.bloodGroup.name,
        'city': d.city,
        'dob': d.dob.toIso8601String(),
        'gender': d.gender,
        'lastDonationDate': d.lastDonationDate?.toIso8601String(),
        'isVerified': d.isVerified,
        'isAdmin': d.isAdmin,
        'latitude': d.latitude,
        'longitude': d.longitude,
        'referralCode': d.referralCode,
        'referredByCode': d.referredByCode,
      };

  BloodEvent _eventFromJson(Map<String, dynamic> j) {
    return BloodEvent(
      id: j['id'] ?? '',
      title: j['title'] ?? '',
      organizer: j['organizer'] ?? '',
      venue: j['venue'] ?? '',
      startDateTime: DateTime.parse(j['start_date_time'] ?? j['startDateTime']),
      endDateTime: DateTime.parse(j['end_date_time'] ?? j['endDateTime']),
      capacity: j['capacity'] ?? 50,
      registeredDonorIds: (j['registered_donor_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      latitude: j['latitude'] != null ? (j['latitude'] as num).toDouble() : null,
      longitude: j['longitude'] != null ? (j['longitude'] as num).toDouble() : null,
    );
  }

  BloodRequest _requestFromJson(Map<String, dynamic> j) {
    return BloodRequest(
      id: j['id'] ?? '',
      requesterName: j['requester_name'] ?? j['requesterName'] ?? '',
      requesterPhone: j['requester_phone'] ?? j['requesterPhone'] ?? '',
      patientName: j['patient_name'] ?? j['patientName'],
      medicalReason: j['medical_reason'] ?? j['medicalReason'],
      bloodGroup: BloodGroup.values.firstWhere(
        (e) => e.name == j['blood_group'] || e.label == j['blood_group'],
        orElse: () => BloodGroup.oPos,
      ),
      unitsNeeded: j['units_needed'] ?? j['unitsNeeded'] ?? 1,
      hospital: j['hospital'] ?? '',
      city: j['city'] ?? '',
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.name == j['urgency'] || e.label == j['urgency'],
        orElse: () => UrgencyLevel.urgent,
      ),
      createdAt: j['created_at'] != null ? DateTime.parse(j['created_at'].toString()) : DateTime.now(),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == j['status'],
        orElse: () => RequestStatus.open,
      ),
      matchedDonorIds: (j['matched_donor_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      latitude: j['latitude'] != null ? (j['latitude'] as num).toDouble() : null,
      longitude: j['longitude'] != null ? (j['longitude'] as num).toDouble() : null,
    );
  }

  @override
  Future<List<Donor>> getDonors() async {
    try {
      final res = await apiClient.get('/api/donors');
      if (res is List) {
        _cachedDonors.clear();
        _cachedDonors.addAll(res.map((j) => _donorFromJson(j as Map<String, dynamic>)));
      }
    } catch (_) {}
    return List.unmodifiable(_cachedDonors);
  }

  @override
  Future<Donor?> getDonorByPhone(String phone) async {
    try {
      final res = await apiClient.get('/api/donors/by-phone/$phone');
      if (res is Map<String, dynamic>) {
        final donor = _donorFromJson(res);
        final idx = _cachedDonors.indexWhere((d) => d.id == donor.id);
        if (idx >= 0) {
          _cachedDonors[idx] = donor;
        } else {
          _cachedDonors.add(donor);
        }
        return donor;
      }
    } catch (_) {}
    try {
      return _cachedDonors.firstWhere((d) => d.phone == phone);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Donor?> getDonorById(String id) async {
    try {
      return _cachedDonors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Donor> upsertDonor(Donor donor) async {
    try {
      final res = await apiClient.post('/api/donors', body: _donorToJson(donor));
      if (res is Map<String, dynamic>) {
        final saved = _donorFromJson(res);
        final idx = _cachedDonors.indexWhere((d) => d.id == saved.id);
        if (idx >= 0) {
          _cachedDonors[idx] = saved;
        } else {
          _cachedDonors.add(saved);
        }
        return saved;
      }
    } catch (_) {}
    final idx = _cachedDonors.indexWhere((d) => d.id == donor.id || d.phone == donor.phone);
    if (idx >= 0) {
      _cachedDonors[idx] = donor;
    } else {
      _cachedDonors.add(donor);
    }
    return donor;
  }

  @override
  Future<List<BloodEvent>> getEvents() async {
    try {
      final res = await apiClient.get('/api/events');
      if (res is List) {
        _cachedEvents.clear();
        _cachedEvents.addAll(res.map((j) => _eventFromJson(j as Map<String, dynamic>)));
      }
    } catch (_) {}
    return List.unmodifiable(_cachedEvents);
  }

  @override
  Future<void> registerDonorForEvent(String eventId, String donorId) async {
    final donor = await getDonorById(donorId);
    if (donor != null && donor.isUnder18) {
      throw StateError('Donors must be at least 18 years old to register for blood donation.');
    }
    if (donor != null && donor.isOverAge) {
      throw StateError('Voluntary blood donation upper age limit is 65 years.');
    }
    try {
      await apiClient.post('/api/events/$eventId/register', body: {'donorId': donorId});
    } catch (_) {}
    final eventMatches = _cachedEvents.where((e) => e.id == eventId);
    if (eventMatches.isNotEmpty) {
      final ev = eventMatches.first;
      if (!ev.registeredDonorIds.contains(donorId)) ev.registeredDonorIds.add(donorId);
    }
  }

  @override
  Future<List<DonationRecord>> getDonationHistory(String donorId) async {
    try {
      final res = await apiClient.get('/api/donations', queryParams: {'donorId': donorId});
      if (res is List) {
        return res
            .map((j) => DonationRecord(
                  id: j['id'] ?? '',
                  donorId: j['donor_id'] ?? donorId,
                  eventId: j['event_id'],
                  donationDate: DateTime.parse(j['donation_date'] ?? DateTime.now().toIso8601String()),
                  unitsMl: j['units_ml'] ?? 450,
                  verifiedBy: j['verified_by'] ?? 'Self-reported',
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<DonationRecord>> getAllDonationHistory() async {
    try {
      final res = await apiClient.get('/api/donations');
      if (res is List) {
        return res
            .map((j) => DonationRecord(
                  id: j['id'] ?? '',
                  donorId: j['donor_id'] ?? '',
                  eventId: j['event_id'],
                  donationDate: DateTime.parse(j['donation_date'] ?? DateTime.now().toIso8601String()),
                  unitsMl: j['units_ml'] ?? 450,
                  verifiedBy: j['verified_by'] ?? 'Self-reported',
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> logDonation(String donorId, {String? eventId, String verifiedBy = 'Self-reported'}) async {
    final donor = await getDonorById(donorId);
    if (donor != null && donor.isUnder18) {
      throw StateError('Donors must be at least 18 years old to donate blood.');
    }
    if (donor != null && donor.isOverAge) {
      throw StateError('Voluntary blood donation upper age limit is 65 years.');
    }
    final recordId = _uuid.v4();
    final now = DateTime.now();
    try {
      await apiClient.post('/api/donations', body: {
        'id': recordId,
        'donorId': donorId,
        'eventId': eventId,
        'donationDate': now.toIso8601String(),
        'unitsMl': 450,
        'verifiedBy': verifiedBy,
      });
    } catch (_) {}
    if (donor != null) {
      await upsertDonor(donor.copyWith(lastDonationDate: now));
    }
  }

  @override
  Future<List<BloodRequest>> getRequests() async {
    try {
      final res = await apiClient.get('/api/requests');
      if (res is List) {
        _cachedRequests.clear();
        _cachedRequests.addAll(res.map((j) => _requestFromJson(j as Map<String, dynamic>)));
      }
    } catch (_) {}
    return List.unmodifiable(_cachedRequests);
  }

  @override
  Future<BloodRequest> raiseRequest(BloodRequest request) async {
    try {
      final res = await apiClient.post('/api/requests', body: {
        'id': request.id,
        'requesterName': request.requesterName,
        'requesterPhone': request.requesterPhone,
        'patientName': request.patientName,
        'medicalReason': request.medicalReason,
        'bloodGroup': request.bloodGroup.name,
        'unitsNeeded': request.unitsNeeded,
        'hospital': request.hospital,
        'city': request.city,
        'urgency': request.urgency.name,
        'latitude': request.latitude,
        'longitude': request.longitude,
      });
      if (res is Map<String, dynamic>) {
        final created = _requestFromJson(res);
        final matches = await findMatchingDonors(created);
        created.matchedDonorIds.addAll(matches.map((m) => m.donor.id));
        _cachedRequests.insert(0, created);
        return created;
      }
    } catch (_) {}
    _cachedRequests.insert(0, request);
    final matches = await findMatchingDonors(request);
    request.matchedDonorIds.addAll(matches.map((m) => m.donor.id));
    return request;
  }

  @override
  Future<List<DonorMatch>> findMatchingDonors(BloodRequest request) async {
    final compatible = compatibleDonorsFor(request.bloodGroup).toSet();
    final donors = await getDonors();
    final candidates = donors.where((d) => compatible.contains(d.bloodGroup) && d.isAgeEligible).toList();

    final matches = candidates.map((d) {
      double? distanceKm;
      if (request.hasLocation && d.hasLocation) {
        distanceKm = haversineDistanceKm(
          request.latitude!,
          request.longitude!,
          d.latitude!,
          d.longitude!,
        );
      }
      return DonorMatch(donor: d, distanceKm: distanceKm);
    }).toList();

    matches.sort((a, b) {
      if (a.donor.isEligibleNow != b.donor.isEligibleNow) {
        return a.donor.isEligibleNow ? -1 : 1;
      }
      if (a.distanceKm != null && b.distanceKm != null) {
        final cmp = a.distanceKm!.compareTo(b.distanceKm!);
        if (cmp != 0) return cmp;
      } else {
        final aCity = a.donor.city == request.city ? 0 : 1;
        final bCity = b.donor.city == request.city ? 0 : 1;
        if (aCity != bCity) return aCity - bCity;
      }
      final aLast = a.donor.lastDonationDate ?? DateTime(2000);
      final bLast = b.donor.lastDonationDate ?? DateTime(2000);
      return aLast.compareTo(bLast);
    });

    return matches;
  }

  @override
  Future<BloodEvent> addEvent(BloodEvent event) async {
    _cachedEvents.add(event);
    return event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _cachedEvents.removeWhere((e) => e.id == eventId);
  }

  @override
  Future<void> updateRequestStatus(String requestId, RequestStatus status) async {
    final matches = _cachedRequests.where((r) => r.id == requestId);
    if (matches.isNotEmpty) matches.first.status = status;
  }

  @override
  Future<List<AppNotification>> getNotifications(String donorId) async {
    try {
      final res = await apiClient.get('/api/notifications', queryParams: {'donorId': donorId});
      if (res is List) {
        return res
            .map((j) => AppNotification(
                  id: j['id'] ?? '',
                  recipientDonorId: j['recipient_donor_id'] ?? donorId,
                  type: NotificationType.values.firstWhere(
                    (e) => e.name == j['type'],
                    orElse: () => NotificationType.matchFound,
                  ),
                  title: j['title'] ?? '',
                  body: j['body'] ?? '',
                  isRead: j['is_read'] == true,
                  createdAt: j['created_at'] != null ? DateTime.parse(j['created_at'].toString()) : DateTime.now(),
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<void> addNotification(AppNotification notification) async {}

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await apiClient.patch('/api/notifications/$notificationId/read');
    } catch (_) {}
  }
}
