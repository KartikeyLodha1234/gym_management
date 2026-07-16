import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'dashboard.dart';
import 'member.dart';
import 'payments.dart';
import 'events.dart';
import 'feeplan.dart';
import 'staff.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _attendanceList = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final members = await DatabaseHelper.instance.queryAllMembers();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attendance = await DatabaseHelper.instance.queryAttendanceByDate(dateStr);
    setState(() {
      _allMembers = members;
      _attendanceList = attendance;
      _isLoading = false;
    });
  }

  Future<void> _markAttendance(Map<String, dynamic> member) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Check if already marked for today
    final alreadyMarked = _attendanceList.any((a) => a['memberId'] == member['id']);
    
    if (alreadyMarked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member['name']} is already marked present for today!'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final attendanceData = {
      'memberId': member['id'],
      'memberName': member['name'],
      'date': dateStr,
      'time': DateFormat('hh:mm KK').format(DateTime.now()),
      'status': 'Present'
    };

    await DatabaseHelper.instance.insertAttendance(attendanceData);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance marked for ${member['name']}'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Attendance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: _buildSidebar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Mark Attendance'),
                  _buildCard([
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) => option['name'],
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return _allMembers.where((Map<String, dynamic> option) {
                          return option['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                                 option['id'].toString().contains(textEditingValue.text);
                        });
                      },
                      onSelected: _markAttendance,
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search Member to Check-in',
                            hintText: 'Enter Name or ID...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_search),
                          ),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Attendance: ${DateFormat('dd MMM').format(_selectedDate)}'),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month, color: Color(0xFF2D6A4F)),
                        label: const Text('Change Date', style: TextStyle(color: Color(0xFF2D6A4F))),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _loadData();
                          }
                        },
                      ),
                    ],
                  ),
                  
                  _buildCard([
                    if (_attendanceList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No attendance records for this date.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _attendanceList.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final record = _attendanceList[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                              child: const Icon(Icons.check, color: Color(0xFF2D6A4F)),
                            ),
                            title: Text(record['memberName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: ${record['memberId']} • Time: ${record['time']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteAttendance(record['id']);
                                _loadData();
                              },
                            ),
                          );
                        },
                      ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSidebar(BuildContext context) {
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
            _buildSidebarTile(icon: Icons.grid_view, title: 'Dashboard', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
            }),
            _buildSidebarTile(icon: Icons.people, title: 'Members List', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemberPage()));
            }),
            _buildSidebarTile(icon: Icons.how_to_reg, title: 'Attendance', isSelected: true, onTap: () => Navigator.pop(context)),
            _buildSidebarTile(icon: Icons.badge, title: 'Staff', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StaffPage()));
            }),
            _buildSidebarTile(icon: Icons.payment, title: 'Payments', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsPage()));
            }),
            _buildSidebarTile(icon: Icons.event, title: 'Event Planner', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EventsPage()));
            }),
            _buildSidebarTile(icon: Icons.receipt_long, title: 'Fee Plans', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FeePlanPage()));
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            ),
            const Spacer(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarTile({required IconData icon, required String title, required VoidCallback onTap, bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey[600]),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey[600])),
      tileColor: isSelected ? const Color(0xFF2D6A4F).withValues(alpha: 0.08) : null,
      onTap: onTap,
    );
  }
}
