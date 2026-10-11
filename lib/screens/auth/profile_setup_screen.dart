import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/donor.dart';
import '../../providers/app_state.dart';
import '../../widgets/eligibility_guidelines_dialog.dart';
import '../home/home_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phone;
  const ProfileSetupScreen({super.key, required this.phone});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _lastDonationCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  BloodGroup? _bloodGroup;
  String _gender = 'Male';
  DateTime? _dob;
  DateTime? _lastDonationDate;
  String? _referralError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _dobCtrl.dispose();
    _lastDonationCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate({required bool isDob}) async {
    final now = DateTime.now();
    final df = DateFormat('dd MMM yyyy');

    if (isDob) {
      // Voluntary blood donors must be between 18 and 65 years old
      final maxDob = DateTime(now.year - 18, now.month, now.day);
      final minDob = DateTime(now.year - 65, now.month, now.day);

      DateTime initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
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
          final age = _calculateAge(picked);
          _dobCtrl.text = '${df.format(picked)} ($age yrs)';
          if (_lastDonationDate != null && _lastDonationDate!.isBefore(picked)) {
            _lastDonationDate = null;
            _lastDonationCtrl.clear();
          }
        });
      }
    } else {
      DateTime minDonationDate = _dob != null
          ? DateTime(_dob!.year + 18, _dob!.month, _dob!.day)
          : DateTime(now.year - 10, now.month, now.day);
      if (minDonationDate.isAfter(now)) {
        minDonationDate = DateTime(now.year - 10, now.month, now.day);
      }

      DateTime initial = _lastDonationDate ?? now;
      if (initial.isAfter(now)) initial = now;
      if (initial.isBefore(minDonationDate)) initial = minDonationDate;

      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: minDonationDate,
        lastDate: now,
        helpText: 'SELECT LAST DONATION DATE',
      );
      if (picked != null) {
        setState(() {
          _lastDonationDate = picked;
          _lastDonationCtrl.text = df.format(picked);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _bloodGroup == null || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    final age = _calculateAge(_dob!);
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donors must be at least 18 years old to register.')),
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
    final enteredCode = _referralCtrl.text.trim().toUpperCase();
    String? referredByCode;
    if (enteredCode.isNotEmpty) {
      // Normalize away dashes/spaces so "RAKTD10000", "rakt d1 00 00", and
      // "RAKT-D10000" all match the same stored code.
      String normalize(String s) => s.replaceAll(RegExp(r'[\s-]'), '');
      final normalizedEntry = normalize(enteredCode);
      final referrerMatches = appState.donors.where((d) => normalize(d.referralCode) == normalizedEntry);
      if (referrerMatches.isEmpty) {
        setState(() => _referralError = 'This referral code doesn\'t match any existing donor.');
        return;
      }
      // Store the referrer's actual canonical code, not the raw (possibly
      // differently-formatted) text the user typed.
      referredByCode = referrerMatches.first.referralCode;
    }

    final donor = Donor(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      phone: widget.phone,
      bloodGroup: _bloodGroup!,
      city: _cityCtrl.text.trim(),
      dob: _dob!,
      gender: _gender,
      lastDonationDate: _lastDonationDate,
      isVerified: false,
      referredByCode: referredByCode,
    );
    await appState.completeSignup(donor);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Donor Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<BloodGroup>(
                initialValue: _bloodGroup,
                decoration: const InputDecoration(labelText: 'Blood Group *', border: OutlineInputBorder()),
                items: BloodGroup.values
                    .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                    .toList(),
                validator: (v) => v == null ? 'Blood Group is required' : null,
                onChanged: (v) => setState(() => _bloodGroup = v),
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
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v ?? 'Male'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                onTap: () => _pickDate(isDob: true),
                decoration: InputDecoration(
                  labelText: 'Date of Birth * (Eligible: 18 - 65 years)',
                  hintText: 'Tap to select your Date of Birth',
                  helperText: _dob != null
                      ? 'Age: ${_calculateAge(_dob!)} years old (Eligible 18 - 65)'
                      : 'Voluntary donors must be between 18 and 65 years old',
                  helperStyle: TextStyle(
                    color: _dob != null ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                    fontWeight: _dob != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) {
                  if (_dob == null) return 'Date of Birth is required';
                  final a = _calculateAge(_dob!);
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
              TextFormField(
                controller: _lastDonationCtrl,
                readOnly: true,
                onTap: () => _pickDate(isDob: false),
                decoration: InputDecoration(
                  labelText: 'Last Donation Date (if any)',
                  hintText: 'Tap to select last donation date',
                  helperText: 'Leave blank if you are a first-time donor',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.history_outlined),
                  suffixIcon: _lastDonationDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear date',
                          onPressed: () {
                            setState(() {
                              _lastDonationDate = null;
                              _lastDonationCtrl.clear();
                            });
                          },
                        )
                      : const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _referralCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Referral Code (optional)',
                  hintText: 'e.g. RAKT-A1B2C3',
                  border: const OutlineInputBorder(),
                  errorText: _referralError,
                ),
                onChanged: (_) {
                  if (_referralError != null) setState(() => _referralError = null);
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'If a friend invited you, enter their code here — they\'ll get credit and you both help grow the donor community.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
                  child: const Text('Save & Continue', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
