import 'package:flutter/material.dart';
import '../models/donor.dart';
import 'blood_group_chip.dart';
import 'eligibility_badge.dart';

class DonorCard extends StatelessWidget {
  final Donor donor;
  final VoidCallback? onContact;
  final String? distanceLabel;

  const DonorCard({super.key, required this.donor, this.onContact, this.distanceLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: BloodGroupChip(group: donor.bloodGroup),
        title: Row(children: [
          Expanded(child: Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          if (donor.isVerified) const Icon(Icons.verified, size: 16, color: Color(0xFF1B3A6B)),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    '${donor.city} · Age: ${donor.age} yrs · ${donor.gender}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                if (distanceLabel != null) ...[
                  const Text(' · ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Icon(Icons.near_me, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(distanceLabel!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              EligibilityBadge(donor: donor),
            ],
          ),
        ),
        trailing: onContact == null
            ? null
            : IconButton(icon: const Icon(Icons.phone, color: Color(0xFF2E7D32)), onPressed: onContact),
      ),
    );
  }
}
