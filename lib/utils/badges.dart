import 'package:flutter/material.dart';
import '../models/donor.dart';

class MilestoneBadge {
  final String name;
  final int threshold;
  final IconData icon;
  final Color color;
  const MilestoneBadge({
    required this.name,
    required this.threshold,
    required this.icon,
    required this.color,
  });
}

/// Donation milestone tiers, ordered ascending by threshold (confirmed donations).
const List<MilestoneBadge> kDonationBadges = [
  MilestoneBadge(name: 'First Drop', threshold: 1, icon: Icons.water_drop, color: Color(0xFF1B3A6B)),
  MilestoneBadge(name: 'Bronze Donor', threshold: 3, icon: Icons.military_tech, color: Color(0xFFCD7F32)),
  MilestoneBadge(name: 'Silver Donor', threshold: 5, icon: Icons.military_tech, color: Color(0xFF9E9E9E)),
  MilestoneBadge(name: 'Gold Donor', threshold: 10, icon: Icons.military_tech, color: Color(0xFFD4AF37)),
  MilestoneBadge(name: 'Platinum Donor', threshold: 25, icon: Icons.workspace_premium, color: Color(0xFF7C4DFF)),
  MilestoneBadge(name: 'Lifesaver Legend', threshold: 50, icon: Icons.emoji_events, color: Color(0xFFB3122E)),
];

/// All donation badges already unlocked, given total confirmed donation count.
List<MilestoneBadge> earnedBadges(int donationCount) =>
    kDonationBadges.where((b) => donationCount >= b.threshold).toList();

/// The next donation badge to work towards, or null if every tier is unlocked.
MilestoneBadge? nextBadge(int donationCount) {
  for (final b in kDonationBadges) {
    if (donationCount < b.threshold) return b;
  }
  return null;
}

/// Referral milestone tiers, ordered ascending by threshold (donors successfully referred).
const List<MilestoneBadge> kReferralBadges = [
  MilestoneBadge(name: 'Recruiter', threshold: 1, icon: Icons.person_add_alt_1, color: Color(0xFF1B3A6B)),
  MilestoneBadge(name: 'Community Builder', threshold: 3, icon: Icons.groups, color: Color(0xFF2E7D32)),
  MilestoneBadge(name: 'Ambassador', threshold: 7, icon: Icons.workspace_premium, color: Color(0xFF7C4DFF)),
  MilestoneBadge(name: 'Blood Champion', threshold: 15, icon: Icons.emoji_events, color: Color(0xFFB3122E)),
];

/// All referral badges already unlocked, given total successful referral count.
List<MilestoneBadge> earnedReferralBadges(int referralCount) =>
    kReferralBadges.where((b) => referralCount >= b.threshold).toList();

/// The next referral badge to work towards, or null if every tier is unlocked.
MilestoneBadge? nextReferralBadge(int referralCount) {
  for (final b in kReferralBadges) {
    if (referralCount < b.threshold) return b;
  }
  return null;
}

/// Counts how many donors have [referralCode] recorded as who referred them.
int countReferrals(String referralCode, List<Donor> allDonors) =>
    allDonors.where((d) => d.referredByCode == referralCode).length;
