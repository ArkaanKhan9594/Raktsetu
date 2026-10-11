import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../events/events_screen.dart';
import '../donors/donor_search_screen.dart';
import '../requests/requests_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppState>().isAdmin;

    final screens = [
      const EventsScreen(),
      const DonorSearchScreen(),
      const RequestsScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.event), label: 'Events'),
      const NavigationDestination(icon: Icon(Icons.people), label: 'Donors'),
      const NavigationDestination(icon: Icon(Icons.bloodtype), label: 'Requests'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      if (isAdmin) const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    // Keep the selected index valid if the admin tab disappears/appears (e.g. after sign-out/sign-in).
    if (_index >= screens.length) _index = 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
