import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/blood_event.dart';
import '../../models/blood_request.dart';
import '../../models/donation_record.dart';
import '../../models/donor.dart';
import '../../providers/app_state.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/eligibility_badge.dart';
import '../profile/donor_id_card_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Events'),
            Tab(text: 'Verify Donations'),
            Tab(text: 'Requests'),
            Tab(text: 'Check-In'),
          ]),
        ),
        body: const TabBarView(children: [
          _ManageEventsTab(),
          _VerifyDonationsTab(),
          _ManageRequestsTab(),
          _CheckInTab(),
        ]),
      ),
    );
  }
}

// ------------------------- TAB 1: Manage Events -------------------------

class _ManageEventsTab extends StatelessWidget {
  const _ManageEventsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      final events = [...appState.events]
        ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1B3A6B),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Event', style: TextStyle(color: Colors.white)),
          onPressed: () => _showCreateEventSheet(context),
        ),
        body: events.isEmpty
            ? const Center(child: Text('No events yet. Tap "New Event" to add one.'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: events.length,
                itemBuilder: (_, i) {
                  final e = events[i];
                  final df = DateFormat('d MMM yyyy, h:mm a');
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${e.venue}\n${df.format(e.startDateTime)} · ${e.registeredDonorIds.length}/${e.capacity} registered'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFB3122E)),
                        tooltip: 'Cancel event',
                        onPressed: () => _confirmDelete(context, e),
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }

  void _showCreateEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateEventForm(),
    );
  }

  Future<void> _confirmDelete(BuildContext context, BloodEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this event?'),
        content: Text(
            'This will remove "${event.title}" and its ${event.registeredDonorIds.length} '
            'registration(s). This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Event')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Event'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AppState>().deleteEvent(event.id);
    }
  }
}

class _CreateEventForm extends StatefulWidget {
  const _CreateEventForm();

  @override
  State<_CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<_CreateEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '50');
  DateTime? _start;
  DateTime? _end;

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => isStart ? _start = combined : _end = combined);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _start == null || _end == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill all fields, including start & end time')));
      return;
    }
    final event = BloodEvent(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      organizer: _organizerCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      startDateTime: _start!,
      endDateTime: _end!,
      capacity: int.tryParse(_capacityCtrl.text) ?? 50,
    );
    context.read<AppState>().createEvent(event);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create New Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _organizerCtrl,
                decoration: const InputDecoration(labelText: 'Organizer *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _venueCtrl,
                decoration: const InputDecoration(labelText: 'Venue *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_start == null ? 'Start Date & Time *' : DateFormat('d MMM yyyy, h:mm a').format(_start!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(isStart: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_end == null ? 'End Date & Time *' : DateFormat('d MMM yyyy, h:mm a').format(_end!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(isStart: false),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
                  child: const Text('Create Event', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------- TAB 2: Verify Donations -------------------------

/// Shared by the Verify Donations tab and the Check-In tab: confirms a
/// donation, warning first if the donor isn't actually due yet.
Future<void> confirmDonationWithEligibilityCheck(BuildContext context, Donor donor, String? eventId) async {
  if (donor.isUnder18) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Underage Donor - Ineligible'),
        content: Text(
          '${donor.name} is ${donor.age} years old.\n\n'
          'By law and health safety standards, blood donors must be at least 18 years old to donate blood. '
          'Donations cannot be logged for minors.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
        ],
      ),
    );
    return;
  }

  if (!donor.isEligibleNow) {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donor not yet eligible'),
        content: Text(
            '${donor.name} is not due for another ${donor.daysUntilEligible} day(s) '
            '(90-day gap since their last donation). Confirming anyway will reset their '
            'eligibility clock from today. Proceed only if this is a verified correction.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm Anyway')),
        ],
      ),
    );
    if (proceed != true) return;
  }
  if (context.mounted) {
    await context.read<AppState>().confirmDonationForDonor(donor.id, eventId: eventId);
  }
}

class _VerifyDonationsTab extends StatelessWidget {
  const _VerifyDonationsTab();

  bool _alreadyConfirmed(List<DonationRecord> history, String donorId, String eventId) =>
      history.any((r) => r.donorId == donorId && r.eventId == eventId);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      // Only events that have started (ongoing/past) can have confirmed donations.
      final relevantEvents = appState.events
          .where((e) => e.status != EventStatus.upcoming && e.registeredDonorIds.isNotEmpty)
          .toList()
        ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

      if (relevantEvents.isEmpty) {
        return const Center(child: Text('No ongoing/past events with registered donors yet.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: relevantEvents.length,
        itemBuilder: (_, i) {
          final event = relevantEvents[i];
          final registeredDonors = appState.donors
              .where((d) => event.registeredDonorIds.contains(d.id))
              .toList();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${registeredDonors.length} registered donor(s)'),
              children: registeredDonors.map((donor) {
                final confirmed = _alreadyConfirmed(appState.allDonationHistory, donor.id, event.id);
                return ListTile(
                  leading: BloodGroupChip(group: donor.bloodGroup, size: 34),
                  title: Text(donor.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donor.city),
                      const SizedBox(height: 4),
                      EligibilityBadge(donor: donor),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: confirmed
                      ? const Chip(
                          label: Text('Confirmed', style: TextStyle(fontSize: 11)),
                          backgroundColor: Color(0x1A2E7D32),
                          labelStyle: TextStyle(color: Color(0xFF2E7D32)),
                        )
                      : OutlinedButton(
                          onPressed: () => confirmDonationWithEligibilityCheck(context, donor, event.id),
                          child: const Text('Confirm'),
                        ),
                );
              }).toList(),
            ),
          );
        },
      );
    });
  }
}

// ------------------------- TAB 3: Manage Requests -------------------------

class _ManageRequestsTab extends StatelessWidget {
  const _ManageRequestsTab();

  String _statusLabel(RequestStatus s) => switch (s) {
        RequestStatus.open => 'Open',
        RequestStatus.partiallyFulfilled => 'Partially Fulfilled',
        RequestStatus.fulfilled => 'Fulfilled',
        RequestStatus.closed => 'Closed',
      };

  Color _statusColor(RequestStatus s) => switch (s) {
        RequestStatus.open => const Color(0xFFB3122E),
        RequestStatus.partiallyFulfilled => const Color(0xFFB07000),
        RequestStatus.fulfilled => const Color(0xFF2E7D32),
        RequestStatus.closed => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      final requests = appState.requests;
      if (requests.isEmpty) {
        return const Center(child: Text('No blood requests raised yet.'));
      }
      final df = DateFormat('d MMM, h:mm a');
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final r = requests[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    BloodGroupChip(group: r.bloodGroup, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.unitsNeeded} unit(s) · ${r.hospital}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${r.city} · ${df.format(r.createdAt)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_statusLabel(r.status),
                          style: TextStyle(color: _statusColor(r.status), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text('${r.matchedDonorIds.length} donor(s) matched', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  if (r.status != RequestStatus.fulfilled && r.status != RequestStatus.closed)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (r.status == RequestStatus.open)
                          OutlinedButton(
                            onPressed: () => context
                                .read<AppState>()
                                .resolveRequest(r.id, RequestStatus.partiallyFulfilled),
                            child: const Text('Partially Fulfilled'),
                          ),
                        OutlinedButton(
                          onPressed: () => context
                              .read<AppState>()
                              .resolveRequest(r.id, RequestStatus.fulfilled),
                          child: const Text('Mark Fulfilled'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              context.read<AppState>().resolveRequest(r.id, RequestStatus.closed),
                          child: const Text('Close Request'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// ------------------------- TAB 4: Check-In (QR / Manual) -------------------------

class _CheckInTab extends StatefulWidget {
  const _CheckInTab();

  @override
  State<_CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends State<_CheckInTab> {
  MobileScannerController? _scannerController;
  bool _scanning = false;
  Donor? _foundDonor;
  String? _lookupError;
  final _manualCtrl = TextEditingController();
  String? _selectedEventId;

  @override
  void dispose() {
    _scannerController?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _scanning = true;
      _foundDonor = null;
      _lookupError = null;
      _scannerController = MobileScannerController();
    });
  }

  void _stopScanning() {
    final controller = _scannerController;
    setState(() {
      _scanning = false;
      _scannerController = null;
    });
    Future.microtask(() => controller?.dispose());
  }

  void _handleBarcode(BarcodeCapture capture, AppState appState) {
    if (_foundDonor != null) return;
    final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (code == null || !code.startsWith(kDonorQrPrefix)) return;
    final donorId = code.substring(kDonorQrPrefix.length);
    final matches = appState.donors.where((d) => d.id == donorId);
    if (matches.isEmpty) {
      setState(() => _lookupError = 'QR code not recognized as a valid RaktSetu donor ID.');
      return;
    }
    setState(() {
      _foundDonor = matches.first;
      _lookupError = null;
    });
    _stopScanning();
  }

  void _lookupByPhone(AppState appState) {
    final phone = _manualCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _lookupError = 'Enter a valid 10-digit phone number.');
      return;
    }
    final matches = appState.donors.where((d) => d.phone == phone);
    if (matches.isEmpty) {
      setState(() {
        _foundDonor = null;
        _lookupError = 'No donor found with that phone number.';
      });
      return;
    }
    setState(() {
      _foundDonor = matches.first;
      _lookupError = null;
    });
  }

  void _reset() {
    setState(() {
      _foundDonor = null;
      _lookupError = null;
      _selectedEventId = null;
      _manualCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      if (_foundDonor != null) {
        return _buildDonorFound(context, appState, _foundDonor!);
      }
      return _buildLookup(context, appState);
    });
  }

  Widget _buildLookup(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Scan a donor's QR code, or look them up by phone number.",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_scanning)
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      controller: _scannerController,
                      onDetect: (capture) => _handleBarcode(capture, appState),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      icon: const Icon(Icons.close),
                      onPressed: _stopScanning,
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Donor QR Code'),
            ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const Text('Or enter phone number manually:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: '9XXXXXXXXX',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _lookupByPhone(appState),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A6B)),
                child: const Text('Look Up', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          if (_lookupError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_lookupError!, style: const TextStyle(color: Color(0xFFB3122E))),
            ),
        ],
      ),
    );
  }

  Widget _buildDonorFound(BuildContext context, AppState appState, Donor donor) {
    final ongoingEvents = appState.events.where((e) => e.status == EventStatus.ongoing).toList();
    final selectedEventMatches = _selectedEventId == null
        ? const Iterable<BloodEvent>.empty()
        : appState.events.where((e) => e.id == _selectedEventId);
    final selectedEvent = selectedEventMatches.isEmpty ? null : selectedEventMatches.first;
    final alreadyRegistered = selectedEvent != null && selectedEvent.registeredDonorIds.contains(donor.id);
    final alreadyConfirmedForEvent = _selectedEventId != null &&
        appState.allDonationHistory.any((r) => r.donorId == donor.id && r.eventId == _selectedEventId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  BloodGroupChip(group: donor.bloodGroup, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${donor.city} · +91 ${donor.phone}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        EligibilityBadge(donor: donor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (ongoingEvents.isEmpty)
            const Text('No events are currently live. You can still confirm a donation without linking it to an event.',
                style: TextStyle(color: Colors.grey))
          else ...[
            const Text('Which event is this for? (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedEventId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select live event'),
              items: ongoingEvents.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title))).toList(),
              onChanged: (v) => setState(() => _selectedEventId = v),
            ),
          ],
          const SizedBox(height: 20),
          if (alreadyConfirmedForEvent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Text('Already confirmed for this event', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _confirmCheckIn(context, appState, donor),
              icon: const Icon(Icons.check_circle_outline),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB3122E), padding: const EdgeInsets.symmetric(vertical: 14)),
              label: Text(
                _selectedEventId == null
                    ? 'Confirm Donation (no specific event)'
                    : (alreadyRegistered ? 'Confirm Donation' : 'Register & Confirm Donation'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _reset, child: const Text('Scan / Look Up Another Donor')),
        ],
      ),
    );
  }

  Future<void> _confirmCheckIn(BuildContext context, AppState appState, Donor donor) async {
    if (_selectedEventId != null) {
      final eventMatches = appState.events.where((e) => e.id == _selectedEventId);
      final event = eventMatches.isEmpty ? null : eventMatches.first;
      if (event != null && !event.registeredDonorIds.contains(donor.id)) {
        await appState.registerDonorForEventAsAdmin(_selectedEventId!, donor.id);
      }
    }
    if (!context.mounted) return;
    await confirmDonationWithEligibilityCheck(context, donor, _selectedEventId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checked in ${donor.name}.')));
      _reset();
    }
  }
}
