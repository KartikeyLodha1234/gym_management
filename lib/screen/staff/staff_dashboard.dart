import 'package:flutter/material.dart';
import '../admin/sidebar.dart';
import '../admin/member.dart';
import '../admin/attendance.dart';
import '../admin/staff.dart';
import '../admin/payments.dart';
import '../admin/events.dart';
import '../admin/maintenance.dart';
import '../admin/feeplan.dart';

class StaffDashboard extends StatelessWidget {
  final String role; // Manager, Receptionist, Trainer
  final Map<String, dynamic> userData;

  const StaffDashboard({super.key, required this.role, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6EF),
      appBar: AppBar(
        title: Text('$role Dashboard'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      drawer: _buildRoleSidebar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${userData['name']}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('You are logged in as $role', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _buildRoleSpecificContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSidebar(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2D6A4F)),
            accountName: Text(userData['name']),
            accountEmail: Text(userData['email']),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF2D6A4F))),
          ),
          if (role == 'Manager' || role == 'Receptionist')
            ListTile(leading: const Icon(Icons.people), title: const Text('Members'), onTap: () => _nav(context, const MemberPage())),
          
          ListTile(leading: const Icon(Icons.how_to_reg), title: const Text('Attendance'), onTap: () => _nav(context, const AttendancePage())),
          
          if (role == 'Manager')
            ListTile(leading: const Icon(Icons.badge), title: const Text('Staff Management'), onTap: () => _nav(context, const StaffPage())),
          
          if (role == 'Manager' || role == 'Receptionist')
            ListTile(leading: const Icon(Icons.payment), title: const Text('Payments'), onTap: () => _nav(context, const PaymentsPage())),
          
          if (role == 'Manager' || role == 'Trainer')
            ListTile(leading: const Icon(Icons.build), title: const Text('Maintenance'), onTap: () => _nav(context, const MaintenancePage())),
          
          ListTile(leading: const Icon(Icons.event), title: const Text('Events'), onTap: () => _nav(context, const EventsPage())),
          
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildRoleSpecificContent() {
    return Column(
      children: [
        if (role == 'Manager') ...[
          const Text('Full Control: View Reports, Manage Staff & Finances'),
        ] else if (role == 'Receptionist') ...[
          const Text('Operations: Handle Check-ins & New Registrations'),
        ] else if (role == 'Trainer') ...[
          const Text('Training: Manage Workout Plans & Member Progress'),
        ],
      ],
    );
  }
}
