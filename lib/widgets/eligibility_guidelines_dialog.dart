import 'package:flutter/material.dart';
import '../utils/blood_compatibility.dart';

/// Shows an educational modal with official blood donation eligibility criteria.
Future<void> showEligibilityGuidelinesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.health_and_safety, color: Color(0xFFB3122E)),
          SizedBox(width: 8),
          Text('Donation Eligibility Rules', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ruleItem(
              icon: Icons.person_outline,
              title: 'Age Criteria (18 – 65 Years)',
              desc: 'Voluntary donors must be at least 18 years old (legal consent & physiological circulatory development) up to 65 years. Children and minors (< 18) are strictly prohibited.',
            ),
            const Divider(),
            _ruleItem(
              icon: Icons.scale_outlined,
              title: 'Body Weight (Minimum 45 kg)',
              desc: 'Standard whole blood collection is 350-450 ml (about 8-10% of total blood volume). A minimum weight of 45 kg ensures safe donation without hemodynamic compromise.',
            ),
            const Divider(),
            _ruleItem(
              icon: Icons.hourglass_bottom,
              title: 'Donation Interval (Mandatory 90 Days)',
              desc: 'Whole blood can only be donated once every 90 days (120 days for women) to give bone marrow adequate time to replenish iron, ferritin, and red blood cells.',
            ),
            const Divider(),
            _ruleItem(
              icon: Icons.medical_services_outlined,
              title: 'Hemoglobin & Vitals',
              desc: 'Hemoglobin level must be at least 12.5 g/dL with normal pulse (60-100 bpm) and stable blood pressure.',
            ),
            const Divider(),
            _ruleItem(
              icon: Icons.block,
              title: 'Temporary Deferrals',
              desc: 'Wait 6 months after tattoos, body piercings, or major surgeries. Avoid alcohol for at least 24 hours prior to donation.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.hub_outlined, size: 16),
          label: const Text('Compatibility Chart'),
          onPressed: () {
            Navigator.pop(ctx);
            showBloodCompatibilityModal(context);
          },
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3122E)),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Understood'),
        ),
      ],
    ),
  );
}

Widget _ruleItem({required IconData icon, required String title, required String desc}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1B3A6B), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        ),
      ],
    ),
  );
}
