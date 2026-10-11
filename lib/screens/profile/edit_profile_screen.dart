import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/donor.dart';
import '../../providers/app_state.dart';
import '../../utils/geo.dart';
import '../../widgets/eligibility_guidelines_dialog.dart';

class EditProfileScreen extends StatefulWidget {
  final Donor donor;
  const EditProfileScreen({super.key, required this.donor});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _dobCtrl;
  late BloodGroup _bloodGroup;
  late String _gender;
  late DateTime _dob;
  double? _latitude;
  double? _longitude;
  bool _locatingDevice = false;
  String? _locationStatus;

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    final df = DateFormat('dd MMM yyyy');
    _nameCtrl = TextEditingController(text: widget.donor.name);
    _cityCtrl = TextEditingController(text: widget.donor.city);
    _bloodGroup = widget.donor.bloodGroup;
    _gender = widget.donor.gender;
    _dob = widget.donor.dob;
    _dobCtrl = TextEditingController(text: '${df.format(_dob)} (${_calculateAge(_dob)} yrs)');
    _latitude = widget.donor.latitude;
    _longitude = widget.donor.longitude;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final maxDob = DateTime(now.year - 18, now.month, now.day);
    final minDob = DateTime(now.year - 65, now.month, now.day);

    DateTime initial = _dob;
    if (initial.isAfter(maxDob)) initial = maxDob;
    if (initial.isBefore(minDob)) initial = minDob;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDob,
      lastDate: maxDob,
      helpText: 'SELECT DATE OF BIRTH (ELIGIBLE: 18 - 65 YEARS)',
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        final df = DateFormat('dd MMM yyyy');
        _dobCtrl.text = '${df.format(picked)} (${_calculateAge(picked)} yrs)';
      });
    }
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
        _locationStatus = 'Location updated.';
      } else {
        _locationStatus = result.error ?? 'Could not get location.';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final age = _calculateAge(_dob);
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donors must be at least 18 years old.')),
      );
      return;
    }
    if (age > 65) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voluntary blood donors must be 65 years or younger.')),
      );
      return;
    }

    final appState = context.read<AppState>();

    final bloodGroupChanged = _bloodGroup != widget.donor.bloodGroup;
    final hasHistory = appState.history.isNotEmpty;
    if (bloodGroupChanged && hasHistory) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change blood group?'),
          content: Text(
              'You have existing donation records under ${widget.donor.bloodGroup.label}. '
              'Changing your blood group to ${_bloodGroup.label} is a serious correction — '
              'only do this if your group was recorded incorrectly. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Update It'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final updated = widget.donor.copyWith(
      name: _nameCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      bloodGroup: _bloodGroup,
      gender: _gender,
      dob: _dob,
      latitude: _latitude,
      longitude: _longitude,
    );
    await appState.updateProfile(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: widget.donor.phone,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (cannot be changed)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<BloodGroup>(
                initialValue: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group *', border: OutlineInputBorder()),
                items: BloodGroup.values.map((g) => DropdownMenuItem(value: g, child: Text(g.label))).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => setState(() => _bloodGroup = v ?? _bloodGroup),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _gender = v ?? _gender),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                onTap: _pickDob,
                decoration: InputDecoration(
                  labelText: 'Date of Birth * (Eligible: 18 - 65 years)',
                  hintText: 'Tap to select your date of birth',
                  helperText: 'Age: ${_calculateAge(_dob)} years old (Eligible 18 - 65)',
                  helperStyle: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) {
                  final a = _calculateAge(_dob);
                  if (a < 18) {
                    return 'Donors must be at least 18 years old';
                  }
                  if (a > 65) {
                    return 'Voluntary donors must be 65 years or younger';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => showEligibilityGuidelinesDialog(context),
                  icon: const Icon(Icons.help_outline, size: 14),
                  label: const Text('Who can donate blood?', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _locatingDevice ? null : _useCurrentLocation,
                icon: _locatingDevice
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_latitude != null ? Icons.location_on : Icons.my_location),
                label: Text(_latitude != null
                    ? 'Location on file — tap to refresh'
                    : 'Set my location (improves emergency-request matching)'),
              ),
              if (_locationStatus != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_locationStatus!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
