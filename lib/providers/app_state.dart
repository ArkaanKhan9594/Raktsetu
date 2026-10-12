import 'package:flutter/foundation.dart';
import '../models/donor.dart';
import '../models/blood_event.dart';
import '../models/blood_request.dart';
import '../models/donation_record.dart';
import '../models/donor_match.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/data_repository.dart';

class AppState extends ChangeNotifier {
  final AuthService auth;
  final DataRepository repo;

  AppState({required this.auth, required this.repo});

  Donor? currentDonor;
  List<Donor> donors = [];
  List<BloodEvent> events = [];
  List<BloodRequest> requests = [];
  List<DonationRecord> history = [];
  List<DonationRecord> allDonationHistory = [];
  List<AppNotification> notifications = [];
  bool isLoading = false;

  bool get isAdmin => currentDonor?.isAdmin ?? false;
  int get unreadNotificationCount => notifications.where((n) => !n.isRead).length;

  Future<void> toggleAdminRole() async {
    if (currentDonor != null) {
      currentDonor = currentDonor!.copyWith(isAdmin: !isAdmin);
      if (isAdmin) {
        allDonationHistory = await repo.getAllDonationHistory();
      }
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    isLoading = true;
    notifyListeners();
    donors = await repo.getDonors();
    events = await repo.getEvents();
    requests = await repo.getRequests();
    if (currentDonor != null) {
      history = await repo.getDonationHistory(currentDonor!.id);
      notifications = await repo.getNotifications(currentDonor!.id);
    }
    if (isAdmin) {
      allDonationHistory = await repo.getAllDonationHistory();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshNotifications() async {
    if (currentDonor == null) return;
    notifications = await repo.getNotifications(currentDonor!.id);
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await repo.markNotificationRead(notificationId);
    await _refreshNotifications();
  }

  Future<void> loginWithPhone(String phone) async {
    currentDonor = await repo.getDonorByPhone(phone);
    await loadAll();
    notifyListeners();
  }

  Future<void> completeProfile(Donor donor) async {
    currentDonor = await repo.upsertDonor(donor);
    await loadAll();
    notifyListeners();
  }

  /// First-time signup. Same as [completeProfile], but also resolves the
  /// referral code (if any) the new donor entered and notifies whoever
  /// referred them, so their referral count/badge updates on next load.
  Future<void> completeSignup(Donor donor) async {
    await completeProfile(donor);

    if (donor.referredByCode == null || donor.referredByCode!.isEmpty) return;
    final referrerMatches = donors.where((d) => d.referralCode == donor.referredByCode);
    if (referrerMatches.isEmpty) return;
    final referrer = referrerMatches.first;

    await repo.addNotification(AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recipientDonorId: referrer.id,
      type: NotificationType.referralJoined,
      title: 'Your referral joined RaktSetu!',
      body: '${donor.name} just signed up using your referral code. Thank you for growing the donor community!',
      createdAt: DateTime.now(),
    ));
    if (referrer.id == currentDonor?.id) await _refreshNotifications();
  }

  /// Update the signed-in donor's own profile details (name, blood group,
  /// city, gender, DOB, location). Alias of [completeProfile] kept separate
  /// for readability at call sites.
  Future<void> updateProfile(Donor updated) => completeProfile(updated);

  Future<void> registerForEvent(String eventId) async {
    if (currentDonor == null) return;
    await repo.registerDonorForEvent(eventId, currentDonor!.id);
    events = await repo.getEvents();
    final event = events.firstWhere((e) => e.id == eventId);
    await repo.addNotification(AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recipientDonorId: currentDonor!.id,
      type: NotificationType.eventRegistration,
      title: 'Registration confirmed',
      body: 'You\'re registered for "${event.title}".',
      createdAt: DateTime.now(),
    ));
    await _refreshNotifications();
    notifyListeners();
  }

  Future<void> logDonation({String? eventId}) async {
    if (currentDonor == null || !currentDonor!.isEligibleNow) return;
    await repo.logDonation(currentDonor!.id, eventId: eventId);
    currentDonor = await repo.getDonorByPhone(currentDonor!.phone);
    history = await repo.getDonationHistory(currentDonor!.id);
    notifyListeners();
  }

  Future<List<DonorMatch>> raiseRequestAndMatch(BloodRequest request) async {
    await repo.raiseRequest(request);
    requests = await repo.getRequests();
    final matches = await repo.findMatchingDonors(request);

    for (final m in matches) {
      if (m.donor.id == currentDonor?.id) continue; // don't notify yourself
      await repo.addNotification(AppNotification(
        id: '${DateTime.now().microsecondsSinceEpoch}-${m.donor.id}',
        recipientDonorId: m.donor.id,
        type: NotificationType.matchFound,
        title: 'Your blood type is needed',
        body: '${request.unitsNeeded} unit(s) of ${request.bloodGroup.label} needed at '
            '${request.hospital}, ${request.city} (${request.urgency.label}).',
        createdAt: DateTime.now(),
      ));
    }

    await _refreshNotifications();
    notifyListeners();
    return matches;
  }

  void signOut() {
    auth.signOut();
    currentDonor = null;
    notifyListeners();
  }

  // --- Admin-only operations ---

  Future<void> createEvent(BloodEvent event) async {
    await repo.addEvent(event);
    events = await repo.getEvents();
    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    await repo.deleteEvent(eventId);
    events = await repo.getEvents();
    notifyListeners();
  }

  /// Registers a specific donor (not necessarily the signed-in user) for an
  /// event. Used by the admin Check-In flow for walk-in donors who show up
  /// without having pre-registered.
  Future<void> registerDonorForEventAsAdmin(String eventId, String donorId) async {
    await repo.registerDonorForEvent(eventId, donorId);
    events = await repo.getEvents();
    notifyListeners();
  }

  /// Admin confirms that [donorId] completed a donation (optionally tied to an event).
  Future<void> confirmDonationForDonor(String donorId, {String? eventId}) async {
    final adminName = currentDonor?.name ?? 'Camp Coordinator';
    await repo.logDonation(donorId, eventId: eventId, verifiedBy: 'Verified by $adminName');
    donors = await repo.getDonors();
    allDonationHistory = await repo.getAllDonationHistory();

    await repo.addNotification(AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recipientDonorId: donorId,
      type: NotificationType.donationVerified,
      title: 'Donation verified',
      body: 'Your donation has been verified by $adminName. Thank you for saving lives!',
      createdAt: DateTime.now(),
    ));
    if (donorId == currentDonor?.id) await _refreshNotifications();
    notifyListeners();
  }

  Future<void> resolveRequest(String requestId, RequestStatus status) async {
    await repo.updateRequestStatus(requestId, status);
    requests = await repo.getRequests();

    final request = requests.where((r) => r.id == requestId);
    if (request.isNotEmpty) {
      final requester = await repo.getDonorByPhone(request.first.requesterPhone);
      if (requester != null) {
        final label = switch (status) {
          RequestStatus.fulfilled => 'fulfilled',
          RequestStatus.partiallyFulfilled => 'partially fulfilled',
          RequestStatus.closed => 'closed',
          RequestStatus.open => 'reopened',
        };
        await repo.addNotification(AppNotification(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          recipientDonorId: requester.id,
          type: NotificationType.requestStatusChanged,
          title: 'Your blood request was $label',
          body: 'Your request for ${request.first.unitsNeeded} unit(s) of '
              '${request.first.bloodGroup.label} at ${request.first.hospital} is now $label.',
          createdAt: DateTime.now(),
        ));
        if (requester.id == currentDonor?.id) await _refreshNotifications();
      }
    }
    notifyListeners();
  }
}
