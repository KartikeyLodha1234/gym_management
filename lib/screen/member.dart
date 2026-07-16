import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dashboard.dart';
import 'feeplan.dart';
import 'feeplan.dart';
import 'plan_data.dart';
import 'payments.dart';
import 'events.dart';
import 'staff.dart';
import 'attendance.dart';
import '../database_helper.dart';

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
    _refreshMembers();
  }

  Future<void> _refreshMembers() async {
    final data = await DatabaseHelper.instance.queryAllMembers();
    setState(() {
      _members.clear();
      for (var item in data) {
        final member = Map<String, dynamic>.from(item);
        member['joinDate'] = DateTime.parse(member['joinDate']);
        member['expiryDate'] = DateTime.parse(member['expiryDate']);
        if (member['dob'] != null) {
          member['dob'] = DateTime.parse(member['dob']);
        }
        _members.add(member);
      }
    });
  }

  Future<void> _addMember(Map<String, dynamic> member) async {
    final memberToSave = Map<String, dynamic>.from(member);
    memberToSave['status'] = 'Active';
    memberToSave['joinDate'] = (memberToSave['joinDate'] as DateTime).toIso8601String();
    memberToSave['expiryDate'] = (memberToSave['expiryDate'] as DateTime).toIso8601String();
    if (memberToSave['dob'] != null) {
      memberToSave['dob'] = (memberToSave['dob'] as DateTime).toIso8601String();
    }
    memberToSave.remove('id');

    await DatabaseHelper.instance.insertMember(memberToSave);
    _refreshMembers();
  }

  Future<void> _updateMember(Map<String, dynamic> member) async {
    final memberToSave = Map<String, dynamic>.from(member);
    memberToSave['joinDate'] = (memberToSave['joinDate'] as DateTime).toIso8601String();
    memberToSave['expiryDate'] = (memberToSave['expiryDate'] as DateTime).toIso8601String();
    if (memberToSave['dob'] != null) {
      memberToSave['dob'] = (memberToSave['dob'] as DateTime).toIso8601String();
    }

    await DatabaseHelper.instance.updateMember(memberToSave);
    _refreshMembers();
  }

  Future<void> _deleteMember(int id) async {
    await DatabaseHelper.instance.deleteMember(id);
    _refreshMembers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member deleted'), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredMembers() {
    if (_searchQuery.isEmpty) return _members;
    return _members.where((member) {
      final name = member['name'].toString().toLowerCase();
      final mobile = member['mobile'].toString();
      final id = member['id'].toString();
      return name.contains(_searchQuery.toLowerCase()) ||
          mobile.contains(_searchQuery) ||
          id.contains(_searchQuery);
    }).toList();
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final filteredMembers = _getFilteredMembers();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Kartikey Gym - Members List')),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Name', 'Mobile', 'Plan', 'Age', 'Status'],
            data: filteredMembers.map((m) => [
              m['id'].toString(),
              m['name'].toString(),
              m['mobile'].toString(),
              m['plan'].toString(),
              m['age'].toString(),
              m['status'].toString(),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Members'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Mobile'),
      TextCellValue('Plan'),
      TextCellValue('Age'),
      TextCellValue('Status')
    ]);

    final filteredMembers = _getFilteredMembers();
    for (var m in filteredMembers) {
      sheetObject.appendRow([
        IntCellValue(m['id'] as int),
        TextCellValue(m['name'].toString()),
        TextCellValue(m['mobile'].toString()),
        TextCellValue(m['plan'].toString()),
        IntCellValue(m['age'] as int),
        TextCellValue(m['status'].toString()),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/members_list.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Gym Members List');
    }
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
        title: const Text(
          'Member List',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by ID, Name or Mobile...',
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _exportToPDF,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  tooltip: 'Export PDF',
                ),
                IconButton(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  tooltip: 'Export Excel',
                ),
              ],
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
                        DataColumn(label: Text('Photo', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredMembers.map((member) {
                        return DataRow(cells: [
                          DataCell(
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: member['imagePath'] != null ? FileImage(File(member['imagePath'])) : null,
                              child: member['imagePath'] == null ? const Icon(Icons.person, size: 20) : null,
                            ),
                          ),
                          DataCell(Text(member['id'].toString())),
                          DataCell(Text(member['name'])),
                          DataCell(Text(member['mobile'])),
                          DataCell(Text(member['plan'])),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: member['status'] == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member['status'],
                                style: TextStyle(color: member['status'] == 'Active' ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.visibility, size: 20, color: Colors.blue), onPressed: () => _showViewDialog(member)),
                                IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.orange), onPressed: () => _showEditMemberDialog(context, member)),
                                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteMember(member['id'])),
                              ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberDialog(context),
        backgroundColor: const Color(0xFF2D6A4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member['imagePath'] != null) Center(child: CircleAvatar(radius: 50, backgroundImage: FileImage(File(member['imagePath'])))),
            const SizedBox(height: 15),
            Text('ID: ${member['id']}'),
            Text('Mobile: ${member['mobile']}'),
            Text('Plan: ${member['plan']}'),
            Text('Join Date: ${DateFormat('dd MMM yyyy').format(member['joinDate'])}'),
            Text('Expiry: ${DateFormat('dd MMM yyyy').format(member['expiryDate'])}'),
            Text('Trainer: ${member['trainer']}'),
            Text('Emergency: ${member['emergency']}'),
            Text('Email: ${member['email'] ?? 'N/A'}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, Map<String, dynamic> member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddMemberDialog(
        member: member,
        onSave: _updateMember,
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
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
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
              onDetailsPressed: () {},
            ),
            _buildSidebarTile(icon: Icons.grid_view, title: 'Dashboard', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
            }),
            _buildSidebarTile(icon: Icons.people, title: 'Members List', isSelected: true, onTap: () => Navigator.pop(context)),
            _buildSidebarTile(
              icon: Icons.how_to_reg,
              title: 'Attendance',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AttendancePage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.badge,
              title: 'Staff',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StaffPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.payment,
              title: 'Payments',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.event,
              title: 'Event Planner',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EventsPage()));
              },
            ),
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

class AddMemberDialog extends StatefulWidget {
  final int? nextId;
  final Map<String, dynamic>? member;
  final Function(Map<String, dynamic>) onSave;

  const AddMemberDialog({super.key, this.nextId, this.member, required this.onSave});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _priceController = TextEditingController();
  final _trainerController = TextEditingController();
  final _emergencyController = TextEditingController();
  
  DateTime _dob = DateTime.now().subtract(const Duration(days: 365 * 18));
  DateTime _joinDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  String _plan = PlanData.plans.isNotEmpty ? PlanData.plans[0]['name'] : '1 Month';
  String _gender = 'Male';
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!['name'];
      _mobileController.text = widget.member!['mobile'].replaceAll('+91 ', '');
      _emailController.text = widget.member!['email'] ?? '';
      _emergencyController.text = widget.member!['emergency'].replaceAll('+91 ', '');
      _gender = widget.member!['gender'];
      _dob = widget.member!['dob'] ?? DateTime.now().subtract(const Duration(days: 365 * 18));
      _joinDate = widget.member!['joinDate'];
      _plan = widget.member!['plan'];
      _priceController.text = widget.member!['price'];
      _expiryDate = widget.member!['expiryDate'];
      _trainerController.text = widget.member!['trainer'];
      if (widget.member!['imagePath'] != null) {
        _image = File(widget.member!['imagePath']);
      }
    } else if (PlanData.plans.isNotEmpty) {
      final initialPlan = PlanData.plans.firstWhere((p) => p['name'] == _plan);
      _priceController.text = (initialPlan['price'] as String).replaceAll(',', '');
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
                    final fileName = 'member_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
                    final fileName = 'member_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      title: Text(widget.member == null ? 'Add New Member' : 'Edit Member', style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(radius: 50, backgroundColor: const Color(0xFFE8F5E9), backgroundImage: _image != null ? FileImage(_image!) : null, child: _image == null ? const Icon(Icons.person, size: 50, color: Color(0xFF2D6A4F)) : null),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: const Color(0xFF2D6A4F), child: IconButton(icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white), onPressed: _pickImage))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(initialValue: 'Member ID: ${widget.member?['id'] ?? widget.nextId}', decoration: const InputDecoration(border: OutlineInputBorder()), readOnly: true),
                const SizedBox(height: 15),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? 'Enter name' : null),
                const SizedBox(height: 15),
                TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number', prefixText: '+91 ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter mobile';
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return 'Enter exactly 10 digits';
                  return null;
                }),
                const SizedBox(height: 15),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Mail ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Enter email' : null),
                if (widget.member == null) ...[
                  const SizedBox(height: 15),
                  TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true, validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: 15),
                  TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock)), obscureText: true, validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
                ],
                const SizedBox(height: 15),
                TextFormField(controller: _emergencyController, decoration: const InputDecoration(labelText: 'Emergency Number', prefixText: '+91 ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.contact_phone)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Enter emergency contact' : null),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(value: _gender, items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _gender = v!), decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 15),
                ListTile(contentPadding: EdgeInsets.zero, title: Text('DOB: ${DateFormat('dd MMM yyyy').format(_dob)}'), subtitle: const Text('Minimum 18 years required', style: TextStyle(fontSize: 12)), trailing: const Icon(Icons.calendar_today, color: Color(0xFF2D6A4F)), onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _dob, firstDate: DateTime(1950), lastDate: DateTime.now());
                  if (picked != null) {
                    final age = DateTime.now().year - picked.year;
                    if (age < 18) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member must be 18+')));
                    else setState(() => _dob = picked);
                  }
                }),
                const Divider(),
                DropdownButtonFormField<String>(
                  value: _plan,
                  items: PlanData.plans.map((p) => DropdownMenuItem(value: p['name'] as String, child: Text(p['name'] as String))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _plan = v!;
                      final selectedPlan = PlanData.plans.firstWhere((p) => p['name'] == v);
                      _priceController.text = (selectedPlan['price'] as String).replaceAll(',', '');
                      _updateExpiryDate();
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Membership Plan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.assignment)),
                ),
                const SizedBox(height: 15),
                TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)), keyboardType: TextInputType.number),
                const SizedBox(height: 15),
                TextFormField(controller: _trainerController, decoration: const InputDecoration(labelText: 'Trainer Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.fitness_center), hintText: 'Self or Trainer Name')),
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
              final memberData = {
                'name': _nameController.text,
                'mobile': '+91 ${_mobileController.text}',
                'emergency': '+91 ${_emergencyController.text}',
                'gender': _gender,
                'age': age,
                'dob': _dob.toIso8601String(),
                'email': _emailController.text,
                'joinDate': _joinDate,
                'plan': _plan,
                'price': _priceController.text,
                'expiryDate': _expiryDate,
                'trainer': _trainerController.text.isEmpty ? 'Self' : _trainerController.text,
                'imagePath': _image?.path,
              };
              if (widget.member != null) {
                memberData['id'] = widget.member!['id'];
                memberData['status'] = widget.member!['status'];
                memberData['password'] = widget.member!['password'];
              } else {
                memberData['password'] = _passwordController.text;
              }
              widget.onSave(memberData);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: Text(widget.member == null ? 'Save Member' : 'Update Member', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _updateExpiryDate() {
    setState(() {
      final selectedPlan = PlanData.plans.firstWhere((p) => p['name'] == _plan);
      final durationStr = selectedPlan['duration'] as String;
      if (durationStr.contains('Month')) _expiryDate = _joinDate.add(Duration(days: 30 * int.parse(durationStr.split(' ')[0])));
      else if (durationStr.contains('Year')) _expiryDate = _joinDate.add(Duration(days: 365 * int.parse(durationStr.split(' ')[0])));
      else _expiryDate = _joinDate.add(const Duration(days: 30));
    });
  }
}
