import 'package:flutter/material.dart';
import '../models/donor.dart';
import '../widgets/blood_group_chip.dart';

/// Returns the blood groups whose donors CAN donate to a patient needing [need].
/// (Standard whole-blood donor-compatibility chart.)
List<BloodGroup> compatibleDonorsFor(BloodGroup need) {
  switch (need) {
    case BloodGroup.oNeg:
      return [BloodGroup.oNeg];
    case BloodGroup.oPos:
      return [BloodGroup.oNeg, BloodGroup.oPos];
    case BloodGroup.aNeg:
      return [BloodGroup.oNeg, BloodGroup.aNeg];
    case BloodGroup.aPos:
      return [BloodGroup.oNeg, BloodGroup.oPos, BloodGroup.aNeg, BloodGroup.aPos];
    case BloodGroup.bNeg:
      return [BloodGroup.oNeg, BloodGroup.bNeg];
    case BloodGroup.bPos:
      return [BloodGroup.oNeg, BloodGroup.oPos, BloodGroup.bNeg, BloodGroup.bPos];
    case BloodGroup.abNeg:
      return [BloodGroup.oNeg, BloodGroup.aNeg, BloodGroup.bNeg, BloodGroup.abNeg];
    case BloodGroup.abPos:
      return BloodGroup.values; // universal recipient
  }
}

/// Returns the blood groups a donor with [donorGroup] CAN donate TO.
List<BloodGroup> compatibleRecipientsFor(BloodGroup donorGroup) {
  switch (donorGroup) {
    case BloodGroup.oNeg:
      return BloodGroup.values; // Universal Red Cell Donor
    case BloodGroup.oPos:
      return [BloodGroup.oPos, BloodGroup.aPos, BloodGroup.bPos, BloodGroup.abPos];
    case BloodGroup.aNeg:
      return [BloodGroup.aNeg, BloodGroup.aPos, BloodGroup.abNeg, BloodGroup.abPos];
    case BloodGroup.aPos:
      return [BloodGroup.aPos, BloodGroup.abPos];
    case BloodGroup.bNeg:
      return [BloodGroup.bNeg, BloodGroup.bPos, BloodGroup.abNeg, BloodGroup.abPos];
    case BloodGroup.bPos:
      return [BloodGroup.bPos, BloodGroup.abPos];
    case BloodGroup.abNeg:
      return [BloodGroup.abNeg, BloodGroup.abPos];
    case BloodGroup.abPos:
      return [BloodGroup.abPos]; // Universal Recipient, but can only give red cells to AB+
  }
}

String bloodGroupRole(BloodGroup group) {
  switch (group) {
    case BloodGroup.oNeg:
      return 'Universal Red Cell Donor (can donate to all groups)';
    case BloodGroup.abPos:
      return 'Universal Recipient (can receive from all groups)';
    case BloodGroup.oPos:
      return 'Most common donor type (can donate to any Rh+ recipient)';
    case BloodGroup.abNeg:
      return 'Rare blood group (~1% of population)';
    default:
      return 'Compatible with identical and AB recipients';
  }
}

/// Dialog showing complete blood compatibility matrix so users understand
/// donor-recipient science conceptually.
Future<void> showBloodCompatibilityModal(BuildContext context, {BloodGroup? initialGroup}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _BloodCompatibilityDialog(selected: initialGroup ?? BloodGroup.oNeg),
  );
}

class _BloodCompatibilityDialog extends StatefulWidget {
  final BloodGroup selected;
  const _BloodCompatibilityDialog({required this.selected});

  @override
  State<_BloodCompatibilityDialog> createState() => _BloodCompatibilityDialogState();
}

class _BloodCompatibilityDialogState extends State<_BloodCompatibilityDialog> {
  late BloodGroup _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final canGiveTo = compatibleRecipientsFor(_current);
    final canReceiveFrom = compatibleDonorsFor(_current);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.hub_outlined, color: Color(0xFFB3122E)),
          SizedBox(width: 8),
          Text('Blood Compatibility Guide', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a blood group to see medical compatibility rules:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BloodGroup.values.map((bg) {
                final isSelected = bg == _current;
                return ChoiceChip(
                  label: Text(bg.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFB3122E).withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _current = bg),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3A6B).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  BloodGroupChip(group: _current, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bloodGroupRole(_current),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B3A6B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Can DONATE to patients with:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: canGiveTo.map((g) => BloodGroupChip(group: g, size: 28)).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Can RECEIVE blood from:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: canReceiveFrom.map((g) => BloodGroupChip(group: g, size: 28)).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Why? Blood compatibility depends on A, B antigens on red blood cells and Rh factor (+/-). Mismatched transfusions trigger immune hemagglutination.',
              style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

