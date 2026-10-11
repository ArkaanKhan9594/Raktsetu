enum NotificationType { matchFound, requestStatusChanged, donationVerified, eventRegistration, referralJoined }

class AppNotification {
  final String id;
  final String recipientDonorId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.recipientDonorId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });
}
