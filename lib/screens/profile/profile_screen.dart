import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/donor.dart';
import '../../providers/app_state.dart';
import '../../utils/badges.dart';
import '../../utils/blood_compatibility.dart';
import '../../widgets/blood_group_chip.dart';
import '../../widgets/eligibility_badge.dart';
import '../../widgets/eligibility_guidelines_dialog.dart';
import '../auth/phone_login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'donor_id_card_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          Consumer<AppState>(builder: (context, appState, _) {
            final donor = appState.currentDonor;
            return IconButton(
              tooltip: 'Blood Compatibility Guide',
              icon: const Icon(Icons.hub_outlined),
              onPressed: () => showBloodCompatibilityModal(context, initialGroup: donor?.bloodGroup),
            );
          }),
          Consumer<AppState>(builder: (context, appState, _) {
            final unread = appState.unreadNotificationCount;
            return IconButton(
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text('You will need to verify your phone number again to sign back in.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm != true || !context.mounted) return;
              context.read<AppState>().signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(builder: (context, appState, _) {
        final donor = appState.currentDonor;
        if (donor == null) return const Center(child: Text('Not signed in.'));
        final df = DateFormat('d MMM yyyy');
        final donationCount = appState.history.length;
        final earned = earnedBadges(donationCount);
        final upcoming = nextBadge(donationCount);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              BloodGroupChip(group: donor.bloodGroup, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(donor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${donor.city} · +91 ${donor.phone} · Age: ${donor.age} yrs (${donor.gender})',
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    EligibilityBadge(donor: donor),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen(donor: donor)),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DonorIdCardScreen(donor: donor)),
                    ),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Donor ID'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: donor.isAdmin ? const Color(0xFF1B3A6B).withValues(alpha: 0.08) : null,
              child: SwitchListTile(
                secondary: Icon(
                  donor.isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
                  color: donor.isAdmin ? const Color(0xFF1B3A6B) : Colors.grey,
                  size: 28,
                ),
                title: Text(
                  donor.isAdmin ? 'Role: Camp Admin (Coordinator)' : 'Role: Standard Blood Donor',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  donor.isAdmin
                      ? 'Admin Dashboard active in the bottom navigation bar.'
                      : 'Toggle on to unlock Admin Dashboard (Event creation & Donor verification).',
                  style: const TextStyle(fontSize: 12),
                ),
                value: donor.isAdmin,
                activeColor: const Color(0xFF1B3A6B),
                onChanged: (_) => appState.toggleAdminRole(),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Donation Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () => showEligibilityGuidelinesDialog(context),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Guidelines', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (donor.isUnder18) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3122E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB3122E).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: Color(0xFFB3122E)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Under 18 years old (${donor.age} yrs). By law, blood donors must be at least 18 years old. Eligible starting ${df.format(donor.eighteenthBirthday)}.',
                                style: const TextStyle(fontSize: 13, color: Color(0xFFB3122E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (donor.isOverAge) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB3122E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB3122E).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: Color(0xFFB3122E)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Exceeds donation age limit (${donor.age} yrs). Voluntary blood donors must be 65 years or younger per medical safety standards.',
                                style: const TextStyle(fontSize: 13, color: Color(0xFFB3122E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(donor.lastDonationDate == null
                          ? 'No donations recorded yet.'
                          : 'Last donated on ${df.format(donor.lastDonationDate!)}'),
                      if (donor.eligibleFromDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Next eligible from ${df.format(donor.eligibleFromDate!)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Your Blood Group: ${donor.bloodGroup.label}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => showBloodCompatibilityModal(context, initialGroup: donor.bloodGroup),
                                  child: const Text('View Full Chart',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF1B3A6B), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Can donate red cells to: ${compatibleRecipientsFor(donor.bloodGroup).map((g) => g.label).join(', ')}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (donor.isEligibleNow)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => appState.logDonation(),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Mark a Donation as Completed'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Badges & Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      Text('$donationCount total', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                    const SizedBox(height: 12),
                    if (earned.isEmpty)
                      const Text('No badges yet — your first confirmed donation unlocks "First Drop".',
                          style: TextStyle(color: Colors.grey, fontSize: 13))
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: earned.map((b) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: b.color.withValues(alpha: 0.15),
                                child: Icon(b.icon, color: b.color),
                              ),
                              const SizedBox(height: 4),
                              Text(b.name, style: const TextStyle(fontSize: 10)),
                            ],
                          );
                        }).toList(),
                      ),
                    if (upcoming != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        '${upcoming.threshold - donationCount} more donation(s) to unlock "${upcoming.name}"',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: donationCount / upcoming.threshold,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(upcoming.color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Builder(builder: (context) {
                  final referralCount = countReferrals(donor.referralCode, appState.donors);
                  final earnedRef = earnedReferralBadges(referralCount);
                  final nextRef = nextReferralBadge(referralCount);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Spacer(),
                        Text('$referralCount joined', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3A6B).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1B3A6B).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your referral code', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text(donor.referralCode,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Color(0xFF1B3A6B)),
                              tooltip: 'Invite a friend',
                              onPressed: () => Share.share(
                                'Join me on RaktSetu and help save lives through voluntary blood donation! '
                                'Use my referral code ${donor.referralCode} when you sign up.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (earnedRef.isEmpty)
                        const Text('Invite your first donor to unlock "Recruiter".',
                            style: TextStyle(color: Colors.grey, fontSize: 13))
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: earnedRef.map((b) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: b.color.withValues(alpha: 0.15),
                                  child: Icon(b.icon, color: b.color),
                                ),
                                const SizedBox(height: 4),
                                Text(b.name, style: const TextStyle(fontSize: 10)),
                              ],
                            );
                          }).toList(),
                        ),
                      if (nextRef != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          '${nextRef.threshold - referralCount} more referral(s) to unlock "${nextRef.name}"',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: referralCount / nextRef.threshold,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(nextRef.color),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Donation History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            if (appState.history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No past donations on record.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...appState.history.map((r) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.water_drop, color: Color(0xFFB3122E)),
                      title: Text(df.format(r.donationDate)),
                      subtitle: Text('${r.unitsMl} ml · ${r.verifiedBy}'),
                    ),
                  )),
          ],
        );
      }),
    );
  }
}
