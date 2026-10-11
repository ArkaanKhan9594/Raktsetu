import 'donor.dart';

/// Pairs a candidate donor with their distance from the request/event, when
/// both sides have GPS coordinates available. [distanceKm] is null when
/// distance couldn't be computed (falls back to city-name matching instead).
class DonorMatch {
  final Donor donor;
  final double? distanceKm;
  const DonorMatch({required this.donor, this.distanceKm});
}
