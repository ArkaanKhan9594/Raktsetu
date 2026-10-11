import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/donor.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/eligibility_badge.dart';

/// The prefix embedded in every donor QR code, so the scanner can confirm a
/// scanned code is actually a RaktSetu donor ID before trying to look it up.
const String kDonorQrPrefix = 'raktsetu:donor:';

class DonorIdCardScreen extends StatelessWidget {
  final Donor donor;
  const DonorIdCardScreen({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    final qrData = '$kDonorQrPrefix${donor.id}';
    return Scaffold(
      appBar: AppBar(title: const Text('My Donor ID')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3A6B), Color(0xFF2E5090)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.bloodtype, color: Colors.white),
                    SizedBox(width: 8),
                    Text('RaktSetu Donor ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(donor.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BloodGroupChip(group: donor.bloodGroup, size: 32),
                    const SizedBox(width: 10),
                    EligibilityBadge(donor: donor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(donor.city, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (donor.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Verified Donor', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
