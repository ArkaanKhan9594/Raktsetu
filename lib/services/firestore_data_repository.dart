import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/donor.dart';
import '../models/blood_event.dart';
import '../models/blood_request.dart';
import '../models/donation_record.dart';
import '../models/donor_match.dart';
import '../models/app_notification.dart';
import '../utils/blood_compatibility.dart';
import '../utils/geo.dart';
import 'data_repository.dart';

const _uuid = Uuid();

/// Real Cloud Firestore implementation of DataRepository.
class FirestoreDataRepository implements DataRepository {
  final FirebaseFirestore _firestore;

  FirestoreDataRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references matching firestore.rules
  CollectionReference<Map<String, dynamic>> get _donorsCol =>
      _firestore.collection('donors');
  CollectionReference<Map<String, dynamic>> get _eventsCol =>
      _firestore.collection('events');
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('bloodRequests');
  CollectionReference<Map<String, dynamic>> get _historyCol =>
      _firestore.collection('donationRecords');
  CollectionReference<Map<String, dynamic>> get _notificationsCol =>
      _firestore.collection('notifications');

  // Serializers
  Donor _donorFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Donor(
      id: doc.id,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      bloodGroup: BloodGroup.values.firstWhere(
        (e) => e.name == d['bloodGroup'],
        orElse: () => BloodGroup.oPos,
      ),
      city: d['city'] ?? '',
      dob: d['dob'] != null ? DateTime.parse(d['dob']) : DateTime(2000, 1, 1),
      gender: d['gender'] ?? 'Male',
      lastDonationDate: d['lastDonationDate'] != null
          ? DateTime.parse(d['lastDonationDate'])
          : null,
      isVerified: d['isVerified'] == true,
      isAdmin: d['isAdmin'] == true,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      referralCode: d['referralCode'],
      referredByCode: d['referredByCode'],
    );
  }

  Map<String, dynamic> _donorToMap(Donor d) => {
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

  BloodEvent _eventFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BloodEvent(
      id: doc.id,
      title: d['title'] ?? '',
      organizer: d['organizer'] ?? '',
      venue: d['venue'] ?? '',
      startDateTime: d['startDateTime'] != null
          ? DateTime.parse(d['startDateTime'])
          : DateTime.now(),
      endDateTime: d['endDateTime'] != null
          ? DateTime.parse(d['endDateTime'])
          : DateTime.now(),
      capacity: d['capacity'] ?? 100,
      registeredDonorIds: List<String>.from(d['registeredDonorIds'] ?? []),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> _eventToMap(BloodEvent e) => {
        'title': e.title,
        'organizer': e.organizer,
        'venue': e.venue,
        'startDateTime': e.startDateTime.toIso8601String(),
        'endDateTime': e.endDateTime.toIso8601String(),
        'capacity': e.capacity,
        'registeredDonorIds': e.registeredDonorIds,
        'latitude': e.latitude,
        'longitude': e.longitude,
      };

  BloodRequest _requestFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BloodRequest(
      id: doc.id,
      requesterName: d['requesterName'] ?? '',
      requesterPhone: d['requesterPhone'] ?? '',
      bloodGroup: BloodGroup.values.firstWhere(
        (e) => e.name == d['bloodGroup'],
        orElse: () => BloodGroup.oPos,
      ),
      unitsNeeded: d['unitsNeeded'] ?? 1,
      hospital: d['hospital'] ?? '',
      city: d['city'] ?? '',
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.name == d['urgency'],
        orElse: () => UrgencyLevel.urgent,
      ),
      createdAt: d['createdAt'] != null
          ? DateTime.parse(d['createdAt'])
          : DateTime.now(),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => RequestStatus.open,
      ),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> _requestToMap(BloodRequest r) => {
        'requesterName': r.requesterName,
        'requesterPhone': r.requesterPhone,
        'bloodGroup': r.bloodGroup.name,
        'unitsNeeded': r.unitsNeeded,
        'hospital': r.hospital,
        'city': r.city,
        'urgency': r.urgency.name,
        'createdAt': r.createdAt.toIso8601String(),
        'status': r.status.name,
        'latitude': r.latitude,
        'longitude': r.longitude,
      };

  DonationRecord _historyFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DonationRecord(
      id: doc.id,
      donorId: d['donorId'] ?? '',
      eventId: d['eventId'],
      donationDate: d['donationDate'] != null
          ? DateTime.parse(d['donationDate'])
          : DateTime.now(),
      verifiedBy: d['verifiedBy'] ?? 'Self-reported',
      unitsMl: d['unitsMl'] ?? 350,
    );
  }

  // --- API Implementations ---

  @override
  Future<List<Donor>> getDonors() async {
    final snap = await _donorsCol.get();
    return snap.docs.map(_donorFromDoc).toList();
  }

  @override
  Future<Donor?> getDonorByPhone(String phone) async {
    final snap = await _donorsCol.where('phone', isEqualTo: phone).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _donorFromDoc(snap.docs.first);
  }

  @override
  Future<Donor?> getDonorById(String id) async {
    final doc = await _donorsCol.doc(id).get();
    if (!doc.exists) return null;
    return _donorFromDoc(doc);
  }

  @override
  Future<Donor> upsertDonor(Donor donor) async {
    await _donorsCol.doc(donor.id).set(_donorToMap(donor), SetOptions(merge: true));
    return donor;
  }

  @override
  Future<List<BloodEvent>> getEvents() async {
    final snap = await _eventsCol.get();
    return snap.docs.map(_eventFromDoc).toList();
  }

  @override
  Future<void> registerDonorForEvent(String eventId, String donorId) async {
    final donor = await getDonorById(donorId);
    if (donor != null && (donor.age < 18 || donor.age > 65)) {
      throw StateError('Donors under 18 or over 65 cannot register to donate blood.');
    }
    await _eventsCol.doc(eventId).update({
      'registeredDonorIds': FieldValue.arrayUnion([donorId]),
    });
  }

  @override
  Future<List<DonationRecord>> getDonationHistory(String donorId) async {
    final snap =
        await _historyCol.where('donorId', isEqualTo: donorId).get();
    return snap.docs.map(_historyFromDoc).toList();
  }

  @override
  Future<List<DonationRecord>> getAllDonationHistory() async {
    final snap = await _historyCol.get();
    return snap.docs.map(_historyFromDoc).toList();
  }

  @override
  Future<void> logDonation(String donorId,
      {String? eventId, String verifiedBy = 'Self-reported'}) async {
    final donor = await getDonorById(donorId);
    if (donor != null && donor.age < 18) {
      throw StateError('Cannot record donation: Donor must be at least 18 years old.');
    }
    if (donor != null && donor.age > 65) {
      throw StateError('Cannot record donation: Maximum eligible donor age is 65 years.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    await _historyCol.doc(id).set({
      'donorId': donorId,
      'eventId': eventId,
      'donationDate': now.toIso8601String(),
      'verifiedBy': verifiedBy,
      'unitsMl': 350,
    });

    // Update donor's last donation date
    await _donorsCol.doc(donorId).update({
      'lastDonationDate': now.toIso8601String(),
    });
  }

  @override
  Future<List<BloodRequest>> getRequests() async {
    final snap = await _requestsCol.get();
    return snap.docs.map(_requestFromDoc).toList();
  }

  @override
  Future<BloodRequest> raiseRequest(BloodRequest request) async {
    await _requestsCol.doc(request.id).set(_requestToMap(request));
    return request;
  }

  @override
  Future<List<DonorMatch>> findMatchingDonors(BloodRequest request) async {
    final allDonors = await getDonors();
    final compatible = compatibleDonorsFor(request.bloodGroup).toSet();
    final candidates =
        allDonors.where((d) => compatible.contains(d.bloodGroup) && d.isAgeEligible).toList();

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
      final aLast = a.donor.lastDonationDate?.millisecondsSinceEpoch ?? 0;
      final bLast = b.donor.lastDonationDate?.millisecondsSinceEpoch ?? 0;
      return aLast.compareTo(bLast);
    });

    return matches;
  }

  @override
  Future<BloodEvent> addEvent(BloodEvent event) async {
    await _eventsCol.doc(event.id).set(_eventToMap(event));
    return event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _eventsCol.doc(eventId).delete();
  }

  @override
  Future<void> updateRequestStatus(String requestId, RequestStatus status) async {
    await _requestsCol.doc(requestId).update({'status': status.name});
  }

  @override
  Future<List<AppNotification>> getNotifications(String donorId) async {
    final snap = await _notificationsCol
        .where('recipientDonorId', isEqualTo: donorId)
        .get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return AppNotification(
        id: doc.id,
        recipientDonorId: d['recipientDonorId'] ?? '',
        title: d['title'] ?? '',
        body: d['body'] ?? '',
        type: NotificationType.values.firstWhere(
          (t) => t.name == d['type'],
          orElse: () => NotificationType.matchFound,
        ),
        createdAt: d['createdAt'] != null
            ? DateTime.parse(d['createdAt'])
            : DateTime.now(),
        isRead: d['isRead'] == true,
      );
    }).toList();
  }

  @override
  Future<void> addNotification(AppNotification notification) async {
    await _notificationsCol.doc(notification.id).set({
      'recipientDonorId': notification.recipientDonorId,
      'title': notification.title,
      'body': notification.body,
      'type': notification.type.name,
      'createdAt': notification.createdAt.toIso8601String(),
      'isRead': notification.isRead,
    });
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _notificationsCol.doc(notificationId).update({'isRead': true});
  }
}
