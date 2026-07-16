import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'member.dart';
import 'attendance.dart';
import 'staff.dart';
import 'payments.dart';
import 'events.dart';
import 'feeplan.dart';
import 'userprofile.dart';
import 'maintenance.dart';

class AppSidebar extends StatelessWidget {
  final String currentPage;

  const AppSidebar({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2D6A4F)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Icon(Icons.fitness_center, color: Color(0xFF2D6A4F), size: 40),
                    ),
                  ),
                ),
              ),
              accountName: const Text('Kartikey Gym', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: const Text('admin@kartikeygym.com'),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.grid_view,
                    title: 'Dashboard',
                    isSelected: currentPage == 'Dashboard',
                    onTap: () {
                      if (currentPage != 'Dashboard') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.people,
                    title: 'Members List',
                    isSelected: currentPage == 'Members List',
                    onTap: () {
                      if (currentPage != 'Members List') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemberPage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.how_to_reg,
                    title: 'Attendance',
                    isSelected: currentPage == 'Attendance',
                    onTap: () {
                      if (currentPage != 'Attendance') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AttendancePage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.badge,
                    title: 'Staff',
                    isSelected: currentPage == 'Staff',
                    onTap: () {
                      if (currentPage != 'Staff') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StaffPage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.payment,
                    title: 'Payments',
                    isSelected: currentPage == 'Payments',
                    onTap: () {
                      if (currentPage != 'Payments') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsPage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.build,
                    title: 'Maintenance',
                    isSelected: currentPage == 'Maintenance',
                    onTap: () {
                      if (currentPage != 'Maintenance') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MaintenancePage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.event,
                    title: 'Event Planner',
                    isSelected: currentPage == 'Event Planner',
                    onTap: () {
                      if (currentPage != 'Event Planner') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EventsPage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.receipt_long,
                    title: 'Fee Plans',
                    isSelected: currentPage == 'Fee Plans',
                    onTap: () {
                      if (currentPage != 'Fee Plans') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FeePlanPage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: currentPage == 'Profile',
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF2D6A4F)),
                title: const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF2D6A4F)),
                    title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    tileColor: currentPage == 'Profile' ? const Color(0xFF2D6A4F).withValues(alpha: 0.08) : null,
                    onTap: () {
                      if (currentPage != 'Profile') {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserProfilePage()));
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey[600]),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey[600],
        ),
      ),
      tileColor: isSelected ? const Color(0xFF2D6A4F).withValues(alpha: 0.08) : null,
      onTap: onTap,
    );
  }
}
