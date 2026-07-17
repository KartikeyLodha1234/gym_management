import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'dashboard.dart';
import 'member.dart';
import 'attendance.dart';
import 'staff.dart';
import 'payments.dart';
import 'events.dart';
import 'feeplan.dart';
import 'userprofile.dart';
import 'maintenance.dart';
import '../staff/staff_dashboard.dart';

class AppSidebar extends StatelessWidget {
  final String currentPage;

  const AppSidebar({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    final role = AuthService.instance.currentRole ?? 'Admin';
    final user = AuthService.instance.currentUser ?? {'name': 'Admin', 'email': 'admin@kartikeygym.com'};
    final imagePath = user['imagePath']?.toString();

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2D6A4F)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: (imagePath != null && File(imagePath).existsSync()) 
                    ? FileImage(File(imagePath)) 
                    : null,
                child: (imagePath == null || !File(imagePath).existsSync()) 
                    ? ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const Icon(Icons.fitness_center, color: Color(0xFF2D6A4F), size: 40),
                        ),
                      )
                    : null,
              ),
              accountName: Text(user['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(user['email'].toString()),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Dashboard
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.grid_view,
                    title: 'Dashboard',
                    isSelected: currentPage == 'Dashboard',
                    onTap: () {
                      if (currentPage != 'Dashboard') {
                        if (role == 'Admin') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
                        } else {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StaffDashboard(role: role, userData: user)));
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),

                  // Members List (Admin, Manager, Receptionist)
                  if (role == 'Admin' || role == 'Manager' || role == 'Receptionist')
                    _buildSidebarTile(
                      context: context,
                      icon: Icons.people,
                      title: 'Members List',
                      isSelected: currentPage == 'Members List',
                      onTap: () => _nav(context, 'Members List', const MemberPage()),
                    ),

                  // Attendance (All)
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.how_to_reg,
                    title: 'Attendance',
                    isSelected: currentPage == 'Attendance',
                    onTap: () => _nav(context, 'Attendance', const AttendancePage()),
                  ),

                  // Staff (Admin, Manager)
                  if (role == 'Admin' || role == 'Manager')
                    _buildSidebarTile(
                      context: context,
                      icon: Icons.badge,
                      title: 'Staff',
                      isSelected: currentPage == 'Staff',
                      onTap: () => _nav(context, 'Staff', const StaffPage()),
                    ),

                  // Payments (Admin, Manager, Receptionist)
                  if (role == 'Admin' || role == 'Manager' || role == 'Receptionist')
                    _buildSidebarTile(
                      context: context,
                      icon: Icons.payment,
                      title: 'Payments',
                      isSelected: currentPage == 'Payments',
                      onTap: () => _nav(context, 'Payments', const PaymentsPage()),
                    ),

                  // Maintenance (Admin, Manager, Trainer)
                  if (role == 'Admin' || role == 'Manager' || role == 'Trainer')
                    _buildSidebarTile(
                      context: context,
                      icon: Icons.build,
                      title: 'Maintenance',
                      isSelected: currentPage == 'Maintenance',
                      onTap: () => _nav(context, 'Maintenance', const MaintenancePage()),
                    ),

                  // Events (All)
                  _buildSidebarTile(
                    context: context,
                    icon: Icons.event,
                    title: 'Event Planner',
                    isSelected: currentPage == 'Event Planner',
                    onTap: () => _nav(context, 'Event Planner', const EventsPage()),
                  ),

                  // Fee Plans (Admin only)
                  if (role == 'Admin')
                    _buildSidebarTile(
                      context: context,
                      icon: Icons.receipt_long,
                      title: 'Fee Plans',
                      isSelected: currentPage == 'Fee Plans',
                      onTap: () => _nav(context, 'Fee Plans', const FeePlanPage()),
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
                title: const Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF2D6A4F)),
                    title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    tileColor: currentPage == 'Profile' ? const Color(0xFF2D6A4F).withOpacity(0.08) : null,
                    onTap: () => _nav(context, 'Profile', const UserProfilePage()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () {
                      AuthService.instance.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
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

  void _nav(BuildContext context, String title, Widget page) {
    if (currentPage != title) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
    } else {
      Navigator.pop(context);
    }
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
      tileColor: isSelected ? const Color(0xFF2D6A4F).withOpacity(0.08) : null,
      onTap: onTap,
    );
  }
}
