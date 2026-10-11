class DonationRecord {
  final String id;
  final String donorId;
  final String? eventId;
  final DateTime donationDate;
  final int unitsMl;
  final String verifiedBy;

  DonationRecord({
    required this.id,
    required this.donorId,
    this.eventId,
    required this.donationDate,
    this.unitsMl = 350,
    this.verifiedBy = 'Verified by Camp Coordinator',
  });
}
