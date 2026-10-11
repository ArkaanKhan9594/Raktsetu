import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/blood_request.dart';
import '../../models/donor.dart';
import '../../models/donor_match.dart';
import '../../providers/app_state.dart';
import '../../utils/blood_compatibility.dart';
import '../../utils/geo.dart';
import '../../widgets/donor_card.dart';

class RaiseRequestScreen extends StatefulWidget {
  const RaiseRequestScreen({super.key});

  @override
  State<RaiseRequestScreen> createState() => _RaiseRequestScreenState();
}

class _RaiseRequestScreenState extends State<RaiseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController(text: '1');
  BloodGroup? _bloodGroup;
  UrgencyLevel _urgency = UrgencyLevel.urgent;
  List<DonorMatch>? _matches;

  double? _latitude;
  double? _longitude;
  bool _locatingDevice = false;
  String? _locationStatus;

  @override
  void dispose() {
    _patientCtrl.dispose();
    _reasonCtrl.dispose();
    _hospitalCtrl.dispose();
    _cityCtrl.dispose();
    _unitsCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locatingDevice = true;
      _locationStatus = null;
    });
    final result = await getCurrentDeviceLocation();
    setState(() {
      _locatingDevice = false;
      if (result.isSuccess) {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationStatus = 'Location captured — matching will use real distance.';
      } else {
        _locationStatus = result.error ?? 'Could not get location.';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _bloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields correctly')));
      return;
    }
    final appState = context.read<AppState>();
    final donor = appState.currentDonor;
    final request = BloodRequest(
      id: const Uuid().v4(),
      requesterName: donor?.name ?? 'Guest Requester',
      requesterPhone: donor?.phone ?? 'N/A',
      patientName: _patientCtrl.text.trim().isNotEmpty ? _patientCtrl.text.trim() : null,
      medicalReason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
      bloodGroup: _bloodGroup!,
      unitsNeeded: int.tryParse(_unitsCtrl.text.trim()) ?? 1,
      hospital: _hospitalCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      urgency: _urgency,
      createdAt: DateTime.now(),
      latitude: _latitude,
      longitude: _longitude,
    );
    final matches = await appState.raiseRequestAndMatch(request);
    setState(() => _matches = matches);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise Blood Request'),
        actions: [
          IconButton(
            tooltip: 'Blood Compatibility Guide',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => showBloodCompatibilityModal(context, initialGroup: _bloodGroup),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _matches != null ? _buildResults() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BloodGroup>(
                  initialValue: _bloodGroup,
                  decoration: const InputDecoration(labelText: 'Blood Group Needed *', border: OutlineInputBorder()),
                  items: BloodGroup.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                  validator: (v) => v == null ? 'Required' : null,
                  onChanged: (v) => setState(() => _bloodGroup = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Check Who Can Donate',
                icon: const Icon(Icons.info_outline, color: Color(0xFF1B3A6B)),
                onPressed: () => showBloodCompatibilityModal(context, initialGroup: _bloodGroup),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _patientCtrl,
            decoration: const InputDecoration(
              labelText: 'Patient Name / Case ID *',
              hintText: 'e.g. Ramesh Kumar / Bed 14',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Patient name is required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Medical Reason / Purpose (optional)',
              hintText: 'e.g. Scheduled Surgery, Dengue Platelets, Trauma',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _unitsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Units Needed * (1 unit ≈ 350-450 ml)',
              helperText: 'Typical requirements: 1-4 units per patient',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Units required';
              final n = int.tryParse(v.trim());
              if (n == null || n < 1) return 'Must be at least 1 unit';
              if (n > 20) return 'Max 20 units per request (contact blood bank for mass requisitions)';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _hospitalCtrl,
            decoration: const InputDecoration(labelText: 'Hospital Name & Address *', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cityCtrl,
            decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<UrgencyLevel>(
            initialValue: _urgency,
            decoration: const InputDecoration(
              labelText: 'Urgency Level',
              border: OutlineInputBorder(),
            ),
            items: UrgencyLevel.values.map((u) {
              final subtitle = switch (u) {
                UrgencyLevel.critical => 'Immediate (< 4 hours)',
                UrgencyLevel.urgent => 'Urgent (Within 24 hours)',
                UrgencyLevel.normal => 'Scheduled (Within 2-3 days)',
              };
              return DropdownMenuItem(value: u, child: Text('${u.label} — $subtitle'));
            }).toList(),
            onChanged: (v) => setState(() => _urgency = v ?? UrgencyLevel.urgent),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _locatingDevice ? null : _useCurrentLocation,
            icon: _locatingDevice
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_latitude != null ? Icons.location_on : Icons.my_location),
            label: Text(_latitude != null ? 'Location captured' : 'Use my current location (improves matching accuracy)'),
          ),
          if (_locationStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_locationStatus!,
                  style: TextStyle(fontSize: 12, color: _latitude != null ? Colors.green : Colors.orange.shade800)),
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
              child: const Text('Submit & Find Matching Donors', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final matches = _matches!;
    final usedDistance = matches.any((m) => m.distanceKm != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(
            matches.isEmpty
                ? 'Request posted. No compatible donors found yet — we will notify you as donors become available.'
                : 'Request posted! ${matches.length} compatible donor(s) found, ranked by eligibility'
                    '${usedDistance ? ' and real distance' : ' and city proximity'}. Matched donors have '
                    'been notified in-app. Tap a donor\'s phone icon to call them directly.',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: matches.length,
            itemBuilder: (_, i) => DonorCard(
              donor: matches[i].donor,
              distanceLabel: matches[i].distanceKm != null ? formatDistance(matches[i].distanceKm!) : null,
              onContact: () => _callDonor(matches[i].donor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _callDonor(Donor donor) async {
    final uri = Uri(scheme: 'tel', path: donor.phone);
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open dialer. Number: ${donor.phone}')),
      );
    }
  }
}
