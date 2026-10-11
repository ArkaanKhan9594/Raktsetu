import 'package:flutter/material.dart';
import '../models/donor.dart';

class EligibilityBadge extends StatelessWidget {
  final Donor donor;
  const EligibilityBadge({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    if (donor.isUnder18) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFB3122E).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB3122E), width: 1),
        ),
        child: const Text(
          'Ineligible (Under 18)',
          style: TextStyle(color: Color(0xFFB3122E), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (donor.isOverAge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFB3122E).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB3122E), width: 1),
        ),
        child: const Text(
          'Ineligible (> 65 yrs)',
          style: TextStyle(color: Color(0xFFB3122E), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    final eligible = donor.isEligibleNow;
    final text = eligible
        ? 'Eligible now'
        : 'Eligible in ${donor.daysUntilEligible} days';
    final color = eligible ? const Color(0xFF2E7D32) : const Color(0xFFB07000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
