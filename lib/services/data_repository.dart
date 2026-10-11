import 'package:uuid/uuid.dart';
import '../models/donor.dart';
import '../models/blood_event.dart';
import '../models/blood_request.dart';
import '../models/donation_record.dart';
import '../models/donor_match.dart';
import '../models/app_notification.dart';
import '../utils/blood_compatibility.dart';
import '../utils/geo.dart';

const _uuid = Uuid();

/// Abstraction over the data source. Swap [InMemoryDataRepository] for a
/// Firestore-backed implementation later — see README > Firebase Integration.
abstract class DataRepository {
  Future<List<Donor>> getDonors();
  Future<Donor?> getDonorByPhone(String phone);
  Future<Donor?> getDonorById(String id);
  Future<Donor> upsertDonor(Donor donor);

  Future<List<BloodEvent>> getEvents();
  Future<void> registerDonorForEvent(String eventId, String donorId);

  Future<List<DonationRecord>> getDonationHistory(String donorId);
  Future<List<DonationRecord>> getAllDonationHistory();
  Future<void> logDonation(String donorId, {String? eventId, String verifiedBy = 'Self-reported'});

  Future<List<BloodRequest>> getRequests();
  Future<BloodRequest> raiseRequest(BloodRequest request);
  Future<List<DonorMatch>> findMatchingDonors(BloodRequest request);

  // --- Admin-only operations ---
  Future<BloodEvent> addEvent(BloodEvent event);
  Future<void> deleteEvent(String eventId);
  Future<void> updateRequestStatus(String requestId, RequestStatus status);

  // --- Notifications ---
  Future<List<AppNotification>> getNotifications(String donorId);
  Future<void> addNotification(AppNotification notification);
  Future<void> markNotificationRead(String notificationId);
}

class InMemoryDataRepository implements DataRepository {
  final List<Donor> _donors = [];
  final List<BloodEvent> _events = [];
  final List<DonationRecord> _history = [];
  final List<BloodRequest> _requests = [];
  final List<AppNotification> _notifications = [];

  InMemoryDataRepository() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    _donors.addAll([
      Donor(id: 'd1', name: 'Aarav Shah', phone: '9000000001', bloodGroup: BloodGroup.oNeg, city: 'Ahmedabad', dob: DateTime(1998, 4, 12), gender: 'Male', lastDonationDate: now.subtract(const Duration(days: 100)), isVerified: true, latitude: 23.0225, longitude: 72.5714),
      Donor(id: 'd2', name: 'Priya Mehta', phone: '9000000002', bloodGroup: BloodGroup.abNeg, city: 'Ahmedabad', dob: DateTime(2000, 8, 2), gender: 'Female', lastDonationDate: now.subtract(const Duration(days: 20)), isVerified: true, latitude: 23.0395, longitude: 72.5660),
      Donor(id: 'd3', name: 'Kabir Patel', phone: '9000000003', bloodGroup: BloodGroup.bPos, city: 'Gandhinagar', dob: DateTime(1995, 1, 30), gender: 'Male', lastDonationDate: null, isVerified: true, latitude: 23.2156, longitude: 72.6369),
      Donor(id: 'd4', name: 'Isha Joshi', phone: '9000000004', bloodGroup: BloodGroup.oPos, city: 'Ahmedabad', dob: DateTime(1999, 11, 5), gender: 'Female', lastDonationDate: now.subtract(const Duration(days: 200)), isVerified: true, latitude: 23.0060, longitude: 72.5090),
      Donor(id: 'd5', name: 'Rohan Trivedi', phone: '9000000005', bloodGroup: BloodGroup.aPos, city: 'Surat', dob: DateTime(1997, 6, 18), gender: 'Male', lastDonationDate: now.subtract(const Duration(days: 45)), isVerified: false, latitude: 21.1702, longitude: 72.8311),
      Donor(id: 'admin1', name: 'Camp Coordinator', phone: '9999999999', bloodGroup: BloodGroup.oPos, city: 'Ahmedabad', dob: DateTime(1990, 1, 1), gender: 'Other', isVerified: true, isAdmin: true, latitude: 23.0225, longitude: 72.5714),
    ]);

    _events.addAll([
      BloodEvent(id: 'e1', title: 'Republic Day Blood Camp', organizer: 'Lions Club Ahmedabad', venue: 'Community Hall, Navrangpura', startDateTime: DateTime(2026, 1, 26, 9), endDateTime: DateTime(2026, 1, 26, 17), capacity: 100, registeredDonorIds: ['d1', 'd4'], latitude: 23.0350, longitude: 72.5626),
      BloodEvent(id: 'e2', title: 'College Donor Drive', organizer: 'ASTT Student Council', venue: 'Main Auditorium', startDateTime: now.subtract(const Duration(hours: 2)), endDateTime: now.add(const Duration(hours: 4)), capacity: 60, registeredDonorIds: ['d2'], latitude: 23.0300, longitude: 72.5800),
      BloodEvent(id: 'e3', title: 'Independence Day Mega Camp', organizer: 'Red Cross Society', venue: 'City Ground, Gandhinagar', startDateTime: DateTime(2026, 8, 15, 8), endDateTime: DateTime(2026, 8, 15, 18), capacity: 200, latitude: 23.2200, longitude: 72.6400),
      BloodEvent(id: 'e4', title: 'World Blood Donor Day Camp', organizer: 'NICE Hospital', venue: 'NICE Hospital Campus', startDateTime: DateTime(2027, 6, 14, 9), endDateTime: DateTime(2027, 6, 14, 16), capacity: 150, latitude: 23.0500, longitude: 72.5200),
    ]);

    _history.addAll([
      DonationRecord(id: 'r1', donorId: 'd1', eventId: 'e1', donationDate: now.subtract(const Duration(days: 100))),
      DonationRecord(id: 'r2', donorId: 'd2', eventId: null, donationDate: now.subtract(const Duration(days: 20))),
      DonationRecord(id: 'r3', donorId: 'd4', eventId: 'e1', donationDate: now.subtract(const Duration(days: 200))),
    ]);

    _requests.add(
      BloodRequest(
        id: 'req1',
        requesterName: 'Sunrise Hospital',
        requesterPhone: '9099999999',
        bloodGroup: BloodGroup.abNeg,
        unitsNeeded: 2,
        hospital: 'Sunrise Multispecialty Hospital',
        city: 'Ahmedabad',
        urgency: UrgencyLevel.critical,
        createdAt: now.subtract(const Duration(hours: 3)),
        latitude: 23.0280,
        longitude: 72.5680,
      ),
    );
  }

  @override
  Future<List<Donor>> getDonors() async => List.unmodifiable(_donors);

  @override
  Future<Donor?> getDonorByPhone(String phone) async {
    try {
      return _donors.firstWhere((d) => d.phone == phone);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Donor?> getDonorById(String id) async {
    try {
      return _donors.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Donor> upsertDonor(Donor donor) async {
    final idx = _donors.indexWhere((d) => d.id == donor.id || d.phone == donor.phone);
    if (idx >= 0) {
      _donors[idx] = donor;
    } else {
      _donors.add(donor);
    }
    return donor;
  }

  @override
  Future<List<BloodEvent>> getEvents() async => List.unmodifiable(_events);

  @override
  Future<void> registerDonorForEvent(String eventId, String donorId) async {
    final event = _events.firstWhere((e) => e.id == eventId);
    final donor = _donors.firstWhere((d) => d.id == donorId);
    if (donor.isUnder18) {
      throw StateError('Donors must be at least 18 years old to register for blood donation.');
    }
    if (donor.isOverAge) {
      throw StateError('Voluntary blood donation upper age limit is 65 years.');
    }
    if (!event.registeredDonorIds.contains(donorId) && !event.isFull) {
      event.registeredDonorIds.add(donorId);
    }
  }

  @override
  Future<List<DonationRecord>> getDonationHistory(String donorId) async =>
      _history.where((r) => r.donorId == donorId).toList()
        ..sort((a, b) => b.donationDate.compareTo(a.donationDate));

  @override
  Future<List<DonationRecord>> getAllDonationHistory() async =>
      List.unmodifiable(_history.reversed);

  @override
  Future<void> logDonation(String donorId, {String? eventId, String verifiedBy = 'Self-reported'}) async {
    final donor = _donors.firstWhere((d) => d.id == donorId);
    if (donor.isUnder18) {
      throw StateError('Donors must be at least 18 years old to donate blood.');
    }
    if (donor.isOverAge) {
      throw StateError('Voluntary blood donation upper age limit is 65 years.');
    }
    final updated = donor.copyWith(lastDonationDate: DateTime.now());
    await upsertDonor(updated);
    _history.add(DonationRecord(
      id: _uuid.v4(),
      donorId: donorId,
      eventId: eventId,
      donationDate: DateTime.now(),
      verifiedBy: verifiedBy,
    ));
  }

  @override
  Future<List<BloodRequest>> getRequests() async =>
      List.unmodifiable(_requests.reversed);

  @override
  Future<BloodRequest> raiseRequest(BloodRequest request) async {
    _requests.add(request);
    final matches = await findMatchingDonors(request);
    request.matchedDonorIds.addAll(matches.map((m) => m.donor.id));
    return request;
  }

  /// Ranks eligible, compatible donors by: eligible-now first, then by real
  /// GPS distance (when both request and donor have coordinates), falling
  /// back to same-city string matching when coordinates aren't available,
  /// then by longest time since last donation.
  @override
  Future<List<DonorMatch>> findMatchingDonors(BloodRequest request) async {
    final compatible = compatibleDonorsFor(request.bloodGroup).toSet();
    // Exclude donors under 18 and over 65 years old as they cannot legally/safely donate blood
    final candidates = _donors.where((d) => compatible.contains(d.bloodGroup) && d.isAgeEligible).toList();

    final matches = candidates.map((d) {
      double? distanceKm;
      if (request.hasLocation && d.hasLocation) {
        distanceKm = haversineDistanceKm(
          request.latitude!, request.longitude!, d.latitude!, d.longitude!,
        );
      }
      return DonorMatch(donor: d, distanceKm: distanceKm);
    }).toList();

    matches.sort((a, b) {
      if (a.donor.isEligibleNow != b.donor.isEligibleNow) {
        return a.donor.isEligibleNow ? -1 : 1;
      }

      // Prefer real distance ranking when both sides have it.
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
      return aLast.compareTo(bLast); // older last-donation first = longer rested
    });

    return matches;
  }

  @override
  Future<BloodEvent> addEvent(BloodEvent event) async {
    _events.add(event);
    return event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
  }

  @override
  Future<void> updateRequestStatus(String requestId, RequestStatus status) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.status = status;
  }

  @override
  Future<List<AppNotification>> getNotifications(String donorId) async =>
      _notifications.where((n) => n.recipientDonorId == donorId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> addNotification(AppNotification notification) async {
    _notifications.add(notification);
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final matches = _notifications.where((item) => item.id == notificationId);
    if (matches.isNotEmpty) matches.first.isRead = true;
  }
}
