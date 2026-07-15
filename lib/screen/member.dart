import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final List<Map<String, dynamic>> _members = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _members.addAll([
      {
        'id': 1,
        'name': 'Rahul Sharma',
        'mobile': '+91 9876543210',
        'plan': '1 Year',
        'status': 'Active',
        'joinDate': DateTime.now().subtract(const Duration(days: 30)),
        'expiryDate': DateTime.now().add(const Duration(days: 335)),
        'gender': 'Male',
        'age': 28
      },
      {
        'id': 2,
        'name': 'Priya Patel',
        'mobile': '+91 8765432109',
        'plan': '6 Months',
        'status': 'Active',
        'joinDate': DateTime.now().subtract(const Duration(days: 15)),
        'expiryDate': DateTime.now().add(const Duration(days: 165)),
        'gender': 'Female',
        'age': 24
      },
    ]);
  }

  void _addMember(Map<String, dynamic> member) {
    setState(() {
      member['joinDate'] = DateTime.now();
      member['expiryDate'] = _calculateExpiryDate(member['plan']);
      member['status'] = 'Active';
      _members.add(member);
    });
  }

  DateTime _calculateExpiryDate(String plan) {
    final now = DateTime.now();
    switch (plan) {
      case '1 Month':
        return now.add(const Duration(days: 30));
      case '3 Months':
        return now.add(const Duration(days: 90));
      case '6 Months':
        return now.add(const Duration(days: 180));
      case '1 Year':
        return now.add(const Duration(days: 365));
      default:
        return now.add(const Duration(days: 30));
    }
  }

  List<Map<String, dynamic>> _getFilteredMembers() {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((member) {
      final name = member['name'].toString().toLowerCase();
      final mobile = member['mobile'].toString();
      return name.contains(_searchQuery.toLowerCase()) ||
          mobile.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _getFilteredMembers();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            const Icon(Icons.people, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            const Text(
              'memberslist',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showAddMemberDialog(context),
              child: const Text(
                'add member',
                style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      drawer: _buildSidebar(context),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Total', _members.length, Icons.people, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Active', _members.where((m) => m['status'] == 'Active').length, Icons.check_circle, Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Expiring', _members.where((m) {
                  final expiryDate = m['expiryDate'] as DateTime?;
                  return expiryDate != null && expiryDate.difference(DateTime.now()).inDays <= 7;
                }).length, Icons.warning, Colors.orange),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2D6A4F)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F8E9)),
                      border: TableBorder.symmetric(inside: const BorderSide(color: Colors.black12)),
                      columns: const [
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Age', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredMembers.map((member) {
                        return DataRow(cells: [
                          DataCell(Text(member['id'].toString())),
                          DataCell(Text(member['name'])),
                          DataCell(Text(member['mobile'])),
                          DataCell(Text(member['plan'])),
                          DataCell(Text(member['age'].toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: member['status'] == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member['status'],
                                style: TextStyle(
                                  color: member['status'] == 'Active' ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$count',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddMemberDialog(
        nextId: _members.isEmpty ? 1 : _members.map((m) => m['id'] as int).reduce((a, b) => a > b ? a : b) + 1,
        onSave: _addMember,
      ),
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
            _buildSidebarTile(
              icon: Icons.grid_view,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.people,
              title: 'Members List',
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            ),
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

class AddMemberDialog extends StatefulWidget {
  final int nextId;
  final Function(Map<String, dynamic>) onSave;

  const AddMemberDialog({super.key, required this.nextId, required this.onSave});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  DateTime _dob = DateTime.now().subtract(const Duration(days: 365 * 18));
  String _plan = '1 Month';
  String _gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Member', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: 'Member ID: ${widget.nextId}',
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  readOnly: true,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile (10 digits)',
                    prefixText: '+91 ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter mobile';
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return 'Enter valid 10 digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _gender = v!),
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 15),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('DOB: ${DateFormat('dd MMM yyyy').format(_dob)}'),
                  subtitle: const Text('Minimum 18 years required', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dob,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      final age = DateTime.now().year - picked.year;
                      if (age < 18) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member must be 18+')));
                      } else {
                        setState(() => _dob = picked);
                      }
                    }
                  },
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _plan,
                  items: ['1 Month', '3 Months', '6 Months', '1 Year'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _plan = v!),
                  decoration: const InputDecoration(labelText: 'Membership Plan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.assignment)),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final age = DateTime.now().year - _dob.year;
              if (age < 18) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Age must be 18+')));
                return;
              }
              widget.onSave({
                'id': widget.nextId,
                'name': _nameController.text,
                'mobile': '+91 ${_mobileController.text}',
                'plan': _plan,
                'gender': _gender,
                'age': age,
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: const Text('Save Member', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
