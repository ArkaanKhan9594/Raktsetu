/// Standard whole-blood donation eligibility gap (days), per WHO/NBTC guidance.
const int kEligibilityGapDays = 90;

enum BloodGroup { aPos, aNeg, bPos, bNeg, abPos, abNeg, oPos, oNeg }

extension BloodGroupLabel on BloodGroup {
  String get label => switch (this) {
        BloodGroup.aPos => 'A+',
        BloodGroup.aNeg => 'A-',
        BloodGroup.bPos => 'B+',
        BloodGroup.bNeg => 'B-',
        BloodGroup.abPos => 'AB+',
        BloodGroup.abNeg => 'AB-',
        BloodGroup.oPos => 'O+',
        BloodGroup.oNeg => 'O-',
      };

  bool get isRare => this == BloodGroup.abNeg || this == BloodGroup.bNeg || this == BloodGroup.oNeg;

  static BloodGroup fromLabel(String label) =>
      BloodGroup.values.firstWhere((e) => e.label == label);
}

/// Derives a short, human-shareable referral code from a donor's (unique) id.
/// Deterministic — regenerating from the same id always yields the same code,
/// so it never needs a separate uniqueness check against other donors.
String generateReferralCode(String donorId) {
  final cleaned = donorId.replaceAll('-', '').toUpperCase();
  final slice = cleaned.length >= 6 ? cleaned.substring(0, 6) : cleaned.padRight(6, '0');
  return 'RAKT-$slice';
}

class Donor {
  final String id;
  final String name;
  final String phone;
  final BloodGroup bloodGroup;
  final String city;
  final DateTime dob;
  final String gender;
  final DateTime? lastDonationDate;
  final bool isVerified;
  final bool isAdmin;
  final double? latitude;
  final double? longitude;
  final String referralCode;
  final String? referredByCode;

  Donor({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.city,
    required this.dob,
    required this.gender,
    this.lastDonationDate,
    this.isVerified = false,
    this.isAdmin = false,
    this.latitude,
    this.longitude,
    String? referralCode,
    this.referredByCode,
  }) : referralCode = referralCode ?? generateReferralCode(id);

  bool get hasLocation => latitude != null && longitude != null;

  /// Donor's current age in completed years calculated from [dob].
  int get age {
    final now = DateTime.now();
    int a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  /// Whether the donor is a minor (strictly under 18 years old).
  bool get isUnder18 => age < 18;

  /// Whether the donor exceeds the upper age limit for voluntary blood donors (over 65).
  bool get isOverAge => age > 65;

  /// Whether the donor falls within the medically approved age window for whole blood donation (18 - 65 years).
  bool get isAgeEligible => age >= 18 && age <= 65;

  /// The exact date when the donor turns 18 years old.
  DateTime get eighteenthBirthday => DateTime(dob.year + 18, dob.month, dob.day);

  /// Date from which this donor becomes eligible again based on the 90-day gap.
  /// Null lastDonation => eligible immediately once age is within 18 - 65.
  DateTime? get eligibleFromDate =>
      lastDonationDate?.add(const Duration(days: kEligibilityGapDays));

  /// Blood donation eligibility:
  /// 1. Must be between 18 and 65 years old.
  /// 2. Must satisfy the mandatory 90-day rest period since last donation.
  bool get isEligibleNow {
    if (!isAgeEligible) return false;
    final gate = eligibleFromDate;
    if (gate == null) return true;
    return DateTime.now().isAfter(gate) || DateTime.now().isAtSameMomentAs(gate);
  }

  int get daysUntilEligible {
    if (isUnder18) {
      final diff = eighteenthBirthday.difference(DateTime.now()).inDays;
      return diff <= 0 ? 1 : diff;
    }
    if (isOverAge) return 0;
    final gate = eligibleFromDate;
    if (gate == null) return 0;
    final diff = gate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Human-friendly medical eligibility summary.
  String get eligibilityStatusReason {
    if (isUnder18) {
      return 'Ineligible: Must be at least 18 years old (current age: $age yrs)';
    }
    if (isOverAge) {
      return 'Ineligible: Voluntary blood donors must be 65 or younger (current age: $age yrs)';
    }
    if (eligibleFromDate != null && DateTime.now().isBefore(eligibleFromDate!)) {
      return 'In Recovery: Next eligible in $daysUntilEligible day(s) (90-day gap)';
    }
    return 'Eligible to donate blood';
  }

  Donor copyWith({
    String? name,
    String? city,
    BloodGroup? bloodGroup,
    DateTime? lastDonationDate,
    bool? isVerified,
    bool? isAdmin,
    String? gender,
    DateTime? dob,
    double? latitude,
    double? longitude,
    String? referredByCode,
  }) {
    return Donor(
      id: id,
      name: name ?? this.name,
      phone: phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      city: city ?? this.city,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      referralCode: referralCode,
      referredByCode: referredByCode ?? this.referredByCode,
    );
  }
}
