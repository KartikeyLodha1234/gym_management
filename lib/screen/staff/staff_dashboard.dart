import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database_helper.dart';
import '../admin/sidebar.dart';

class StaffDashboard extends StatefulWidget {
  final String role;
  final Map<String, dynamic> userData;

  const StaffDashboard({super.key, required this.role, required this.userData});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _memberCount = 0;
  int _attendanceToday = 0;
  int _pendingMaintenance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final members = await DatabaseHelper.instance.queryAllMembers();
      final maintenance = await DatabaseHelper.instance.queryAllMaintenance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendance = await DatabaseHelper.instance.queryAttendanceByDate(today);

      setState(() {
        _memberCount = members.length;
        _attendanceToday = attendance.length;
        _pendingMaintenance = maintenance.where((m) => m['status'] == 'Pending').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D6A4F)),
        title: Text('${widget.role} Dashboard', style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
      ),
      drawer: const AppSidebar(currentPage: 'Dashboard'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  const Text('Key Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatCard('Total Members', '$_memberCount', Icons.group, Colors.blue),
                      const SizedBox(width: 15),
                      _buildStatCard("Today's Check-ins", '$_attendanceToday', Icons.how_to_reg, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatCard('Pending Repairs', '$_pendingMaintenance', Icons.build, Colors.orange),
                      const SizedBox(width: 15),
                      _buildStatCard('Total Income', '₹---', Icons.payments, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                  const SizedBox(height: 15),
                  _buildRoleShortcuts(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF409F7A)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${widget.userData['name']}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Role: ${widget.role}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 15),
                const Text('Keep pushing members to reach their fitness goals today!', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Hero(
            tag: 'profile_pic',
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white24,
              backgroundImage: (widget.userData['imagePath'] != null && File(widget.userData['imagePath']).existsSync())
                  ? FileImage(File(widget.userData['imagePath']))
                  : null,
              child: (widget.userData['imagePath'] == null || !File(widget.userData['imagePath']).existsSync())
                  ? const Icon(Icons.person, color: Colors.white, size: 40)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleShortcuts() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        if (widget.role == 'Manager' || widget.role == 'Receptionist')
          _buildShortcut('Add Member', Icons.person_add, Colors.blue, () {}),
        
        _buildShortcut('Mark Attendance', Icons.check_circle, Colors.green, () {}),
        
        if (widget.role == 'Manager' || widget.role == 'Trainer')
          _buildShortcut('Maintenance', Icons.build, Colors.orange, () {}),

        _buildShortcut('Events', Icons.event, Colors.purple, () {}),
      ],
    );
  }

  Widget _buildShortcut(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 55) / 2,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
