import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/donor.dart';
import '../../providers/app_state.dart';
import '../../utils/blood_compatibility.dart';
import '../../widgets/donor_card.dart';

class DonorSearchScreen extends StatefulWidget {
  const DonorSearchScreen({super.key});

  @override
  State<DonorSearchScreen> createState() => _DonorSearchScreenState();
}

class _DonorSearchScreenState extends State<DonorSearchScreen> {
  BloodGroup? _groupFilter;
  String _cityQuery = '';
  bool _onlyEligible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donor Repository'),
        actions: [
          IconButton(
            tooltip: 'Blood Compatibility Guide',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () => showBloodCompatibilityModal(context, initialGroup: _groupFilter),
          ),
        ],
      ),
      body: Consumer<AppState>(builder: (context, appState, _) {
        var donors = appState.donors;
        if (_groupFilter != null) {
          donors = donors.where((d) => d.bloodGroup == _groupFilter).toList();
        }
        if (_cityQuery.isNotEmpty) {
          donors = donors.where((d) => d.city.toLowerCase().contains(_cityQuery.toLowerCase())).toList();
        }
        if (_onlyEligible) {
          donors = donors.where((d) => d.isEligibleNow).toList();
        }

        final eligibleCount = donors.where((d) => d.isEligibleNow).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by city...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _cityQuery = v),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _chip('All', _groupFilter == null, () => setState(() => _groupFilter = null)),
                  ...BloodGroup.values.map((g) =>
                      _chip(g.label, _groupFilter == g, () => setState(() => _groupFilter = g))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${donors.length} donor(s) ($eligibleCount eligible now)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Only eligible', style: TextStyle(fontSize: 12)),
                      Switch(
                        value: _onlyEligible,
                        onChanged: (v) => setState(() => _onlyEligible = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: donors.isEmpty
                  ? const Center(child: Text('No donors match these filters.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: donors.length,
                      itemBuilder: (_, i) => DonorCard(donor: donors[i]),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
