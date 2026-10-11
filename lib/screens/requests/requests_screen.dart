import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/blood_request.dart';
import '../../models/donor.dart';
import '../../providers/app_state.dart';
import '../../utils/blood_compatibility.dart';
import '../../widgets/blood_group_chip.dart';
import 'raise_request_screen.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  Color _urgencyColor(UrgencyLevel u) => switch (u) {
        UrgencyLevel.critical => const Color(0xFFB3122E),
        UrgencyLevel.urgent => const Color(0xFFB07000),
        UrgencyLevel.normal => const Color(0xFF1B3A6B),
      };

  String _statusLabel(RequestStatus s) => switch (s) {
        RequestStatus.open => 'Open',
        RequestStatus.partiallyFulfilled => 'Partially Fulfilled',
        RequestStatus.fulfilled => 'Fulfilled',
        RequestStatus.closed => 'Closed',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Requests'),
        actions: [
          IconButton(
            tooltip: 'Blood Compatibility Guide',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => showBloodCompatibilityModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB3122E),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseRequestScreen())),
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text('Raise Request', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<AppState>(builder: (context, appState, _) {
        final requests = appState.requests;
        if (requests.isEmpty) {
          return const Center(child: Text('No active blood requests right now.'));
        }
        final df = DateFormat('d MMM, h:mm a');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final r = requests[i];
            final isResolved = r.status == RequestStatus.fulfilled || r.status == RequestStatus.closed;
            return Opacity(
              opacity: isResolved ? 0.55 : 1.0,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showRequestDetails(context, r, appState),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: BloodGroupChip(group: r.bloodGroup),
                    title: Text('${r.unitsNeeded} unit(s) · Patient: ${r.effectivePatientName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.hospital}, ${r.city}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          if (r.medicalReason != null && r.medicalReason!.isNotEmpty)
                            Text('Reason: ${r.medicalReason}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Posted ${df.format(r.createdAt)} · ${r.matchedDonorIds.length} eligible donors matched',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('Status: ${_statusLabel(r.status)} · Tap for details & contact',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B3A6B))),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _urgencyColor(r.urgency).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r.urgency.label,
                          style: TextStyle(color: _urgencyColor(r.urgency), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showRequestDetails(BuildContext context, BloodRequest r, AppState appState) {
    final currentDonor = appState.currentDonor;
    final compatibleDonors = compatibleDonorsFor(r.bloodGroup);
    final isCompatible = currentDonor != null && compatibleDonors.contains(currentDonor.bloodGroup);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                BloodGroupChip(group: r.bloodGroup, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.unitsNeeded} unit(s) of ${r.bloodGroup.label} required',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Urgency: ${r.urgency.label}',
                          style: TextStyle(color: _urgencyColor(r.urgency), fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _detailRow(Icons.person, 'Patient Name', r.effectivePatientName),
            if (r.medicalReason != null && r.medicalReason!.isNotEmpty)
              _detailRow(Icons.medical_services_outlined, 'Clinical Reason', r.medicalReason!),
            _detailRow(Icons.local_hospital_outlined, 'Hospital', r.hospital),
            _detailRow(Icons.location_city, 'City', r.city),
            _detailRow(Icons.phone_outlined, 'Contact Person', '${r.requesterName} (+91 ${r.requesterPhone})'),
            const SizedBox(height: 12),
            if (currentDonor != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompatible ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompatible ? const Color(0xFF2E7D32).withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(isCompatible ? Icons.check_circle_outline : Icons.info_outline,
                        color: isCompatible ? const Color(0xFF2E7D32) : Colors.orange.shade800),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isCompatible
                            ? 'Your blood group (${currentDonor.bloodGroup.label}) is compatible with this patient!'
                            : 'Your blood group (${currentDonor.bloodGroup.label}) cannot donate to ${r.bloodGroup.label}. Compatible donors: ${compatibleDonors.map((g) => g.label).join(', ')}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompatible ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Call Requester', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final uri = Uri(scheme: 'tel', path: r.requesterPhone);
                      final launched = await launchUrl(uri);
                      if (!launched && ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Dialer could not open. Call: ${r.requesterPhone}')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Share request',
                  icon: const Icon(Icons.share, color: Color(0xFF1B3A6B)),
                  onPressed: () => Share.share(
                    'URGENT BLOOD NEEDED!\n'
                    'Blood Group: ${r.bloodGroup.label} (${r.unitsNeeded} unit(s))\n'
                    'Patient: ${r.effectivePatientName}\n'
                    'Hospital: ${r.hospital}, ${r.city}\n'
                    'Contact: +91 ${r.requesterPhone}\n'
                    'Shared via RaktSetu',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
