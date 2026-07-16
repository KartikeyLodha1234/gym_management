import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../database_helper.dart';
import 'dashboard.dart';
import 'member.dart';
import 'payments.dart';
import 'events.dart';
import 'feeplan.dart';
import 'attendance.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshStaff();
  }

  Future<void> _refreshStaff() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.queryAllStaff();
    setState(() {
      _staffList = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Staff Management', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: _buildSidebar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staffList.length,
                  itemBuilder: (context, index) {
                    final staff = _staffList[index];
                    return _buildStaffCard(staff);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStaffDialog(),
        backgroundColor: const Color(0xFF2D6A4F),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No staff members added', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap + to add Manager, Trainer or Receptionist', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
          backgroundImage: staff['imagePath'] != null ? FileImage(File(staff['imagePath'])) : null,
          child: staff['imagePath'] == null 
              ? Text(staff['name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(staff['role'], style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.w600, fontSize: 13)),
            Text(staff['phone'], style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
              onPressed: () => _showViewDialog(staff),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
              onPressed: () => _showStaffDialog(staff: staff),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _showDeleteConfirmation(staff['id']),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStaff(int id) async {
    await DatabaseHelper.instance.deleteStaff(id);
    _refreshStaff();
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: const Text('Are you sure you want to remove this staff member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _deleteStaff(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStaffDialog({Map<String, dynamic>? staff}) {
    showDialog(
      context: context,
      builder: (context) => AddStaffDialog(
        staff: staff,
        onSave: (data) async {
          if (staff == null) {
            await DatabaseHelper.instance.insertStaff(data);
          } else {
            data['id'] = staff['id'];
            await DatabaseHelper.instance.updateStaff(data);
          }
          _refreshStaff();
        },
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (staff['imagePath'] != null) 
              Center(child: CircleAvatar(radius: 50, backgroundImage: FileImage(File(staff['imagePath'])))),
            const SizedBox(height: 15),
            Text('Role: ${staff['role']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
            const SizedBox(height: 5),
            Text('Email: ${staff['email']}'),
            Text('Phone: ${staff['phone']}'),
            Text('Joined: ${DateFormat('dd MMM yyyy').format(DateTime.parse(staff['joinDate']))}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
            _buildSidebarTile(icon: Icons.grid_view, title: 'Dashboard', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
            }),
            _buildSidebarTile(icon: Icons.people, title: 'Members List', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemberPage()));
            }),
            _buildSidebarTile(
              icon: Icons.how_to_reg,
              title: 'Attendance',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AttendancePage()));
              },
            ),
            _buildSidebarTile(icon: Icons.badge, title: 'Staff', isSelected: true, onTap: () => Navigator.pop(context)),
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

class AddStaffDialog extends StatefulWidget {
  final Map<String, dynamic>? staff;
  final Function(Map<String, dynamic>) onSave;

  const AddStaffDialog({super.key, this.staff, required this.onSave});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;
  late String _selectedRole;
  File? _image;
  final List<String> _roles = ['Manager', 'Trainer', 'Receptionist'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?['name'] ?? '');
    _emailController = TextEditingController(text: widget.staff?['email'] ?? '');
    _passwordController = TextEditingController(text: widget.staff?['password'] ?? '');
    _phoneController = TextEditingController(text: widget.staff?['phone']?.replaceAll('+91 ', '') ?? '');
    _selectedRole = widget.staff?['role'] ?? 'Trainer';
    if (widget.staff?['imagePath'] != null) {
      _image = File(widget.staff!['imagePath']);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'staff_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
                    setState(() => _image = savedImage);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName = 'staff_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
                    setState(() => _image = savedImage);
                  }
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.staff == null ? 'Add Staff Member' : 'Edit Staff Member', style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50, 
                        backgroundColor: const Color(0xFFE8F5E9), 
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? const Icon(Icons.person, size: 50, color: Color(0xFF2D6A4F)) : null
                      ),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: const Color(0xFF2D6A4F), child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _pickImage))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedRole = v!),
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone), prefixText: '+91 '),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.length != 10 ? 'Enter exactly 10 digits' : null,
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
              widget.onSave({
                'name': _nameController.text,
                'role': _selectedRole,
                'email': _emailController.text,
                'password': _passwordController.text,
                'phone': '+91 ${_phoneController.text}',
                'joinDate': widget.staff?['joinDate'] ?? DateTime.now().toIso8601String(),
                'imagePath': _image?.path,
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: Text(widget.staff == null ? 'Save Staff' : 'Update Staff', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
