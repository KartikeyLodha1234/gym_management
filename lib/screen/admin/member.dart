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
import 'sidebar.dart';
import 'plan_data.dart';
import '../../database_helper.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _plans = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final memberData = await DatabaseHelper.instance.queryAllMembers();
      final planData = await DatabaseHelper.instance.queryAllPlans();
      
      List<Map<String, dynamic>> parsedMembers = [];
      for (var item in memberData) {
        final member = Map<String, dynamic>.from(item);
        
        if (member['id'] != null && member['id'] is String) {
          member['id'] = int.tryParse(member['id'].toString()) ?? 0;
        }

        try {
          if (member['joinDate'] != null && member['joinDate'] is String) {
            member['joinDate'] = DateTime.parse(member['joinDate'].toString());
          }
          if (member['expiryDate'] != null && member['expiryDate'] is String) {
            member['expiryDate'] = DateTime.parse(member['expiryDate'].toString());
          }
          if (member['dob'] != null && member['dob'] is String) {
            member['dob'] = DateTime.parse(member['dob'].toString());
          }
        } catch (e) {
          debugPrint("Date parsing error: $e");
        }
        
        parsedMembers.add(member);
      }

      if (mounted) {
        setState(() {
          _members.clear();
          _members.addAll(parsedMembers);
          _plans = planData;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing data: $e");
    }
  }

  Future<void> _addMember(Map<String, dynamic> member) async {
    final memberToSave = Map<String, dynamic>.from(member);
    memberToSave['status'] = 'Active';
    memberToSave['joinDate'] = (memberToSave['joinDate'] as DateTime).toIso8601String();
    memberToSave['expiryDate'] = (memberToSave['expiryDate'] as DateTime).toIso8601String();

    await DatabaseHelper.instance.insertMember(memberToSave);
    _refreshData();
  }

  Future<void> _updateMember(Map<String, dynamic> member) async {
    final memberToSave = Map<String, dynamic>.from(member);
    memberToSave['joinDate'] = (memberToSave['joinDate'] as DateTime).toIso8601String();
    memberToSave['expiryDate'] = (memberToSave['expiryDate'] as DateTime).toIso8601String();

    await DatabaseHelper.instance.updateMember(memberToSave);
    _refreshData();
  }

  Future<void> _deleteMember(int id) async {
    await DatabaseHelper.instance.deleteMember(id);
    _refreshData();
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
          'memberslist',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      drawer: const AppSidebar(currentPage: 'Members List'),
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
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F8E9)),
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
                              backgroundImage: member['imagePath'] != null ? FileImage(File(member['imagePath'].toString())) : null,
                              child: member['imagePath'] == null ? const Icon(Icons.person, size: 20) : null,
                            ),
                          ),
                          DataCell(Text(member['id'].toString())),
                          DataCell(Text(member['name'].toString())),
                          DataCell(Text(member['mobile'].toString())),
                          DataCell(Text(member['plan'].toString())),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: member['status'].toString() == 'Active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member['status'].toString(),
                                style: TextStyle(color: member['status'].toString() == 'Active' ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12),
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
            Text('Join Date: ${member['joinDate'] != null ? DateFormat('dd MMM yyyy').format(member['joinDate']) : 'N/A'}'),
            Text('Expiry: ${member['expiryDate'] != null ? DateFormat('dd MMM yyyy').format(member['expiryDate']) : 'N/A'}'),
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
        plans: _plans,
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
              color: Colors.grey.withOpacity(0.1),
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
        plans: _plans,
        nextId: _members.isEmpty ? 1 : _members.map((m) => m['id'] as int).reduce((a, b) => a > b ? a : b) + 1,
        onSave: _addMember,
      ),
    );
  }
}

class AddMemberDialog extends StatefulWidget {
  final int? nextId;
  final List<Map<String, dynamic>> plans;
  final Map<String, dynamic>? member;
  final Function(Map<String, dynamic>) onSave;

  const AddMemberDialog({super.key, this.nextId, required this.plans, this.member, required this.onSave});

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
  String _plan = '1 Month';
  String _gender = 'Male';
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.plans.isNotEmpty) {
      _plan = widget.member != null ? widget.member!['plan'].toString() : widget.plans[0]['name'].toString();
    }
    if (widget.member != null) {
      _nameController.text = widget.member!['name'].toString();
      _mobileController.text = widget.member!['mobile'].toString().replaceAll('+91 ', '');
      _emailController.text = widget.member!['email']?.toString() ?? '';
      _emergencyController.text = widget.member!['emergency'].toString().replaceAll('+91 ', '');
      _gender = widget.member!['gender'].toString();
      
      if (widget.member!['dob'] != null) {
        if (widget.member!['dob'] is String) {
          _dob = DateTime.parse(widget.member!['dob']);
        } else {
          _dob = widget.member!['dob'];
        }
      }
      
      _joinDate = widget.member!['joinDate'] is String 
          ? DateTime.parse(widget.member!['joinDate']) 
          : widget.member!['joinDate'];
          
      _expiryDate = widget.member!['expiryDate'] is String 
          ? DateTime.parse(widget.member!['expiryDate']) 
          : widget.member!['expiryDate'];

      _priceController.text = widget.member!['price'].toString();
      _trainerController.text = widget.member!['trainer'].toString();
      _passwordController.text = widget.member!['password']?.toString() ?? '';

      if (widget.member!['imagePath'] != null) {
        _image = File(widget.member!['imagePath'].toString());
      }
    } else if (widget.plans.isNotEmpty) {
      final initialPlan = widget.plans.firstWhere((p) => p['name'] == _plan, orElse: () => widget.plans[0]);
      _priceController.text = initialPlan['price'].toString().replaceAll(',', '');
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
                if (widget.member != null) ...[
                  const SizedBox(height: 15),
                  TextButton.icon(
                    icon: const Icon(Icons.lock_reset, color: Color(0xFF2D6A4F)),
                    label: const Text('Change Password', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
                    onPressed: () {
                      final newPassController = TextEditingController();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Change Password'),
                          content: TextField(
                            controller: newPassController,
                            decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                            obscureText: true,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                if (newPassController.text.length >= 6) {
                                  _passwordController.text = newPassController.text;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated in form. Save to confirm.')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Min 6 characters required')));
                                }
                              },
                              child: const Text('Update'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 15),
                  TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true, validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
                  const SizedBox(height: 15),
                  TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_clock)), obscureText: true, validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
                ],
                const SizedBox(height: 15),
                TextFormField(controller: _emergencyController, decoration: const InputDecoration(labelText: 'Emergency Number', prefixText: '+91 ', border: OutlineInputBorder(), prefixIcon: Icon(Icons.contact_phone)), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Enter emergency contact' : null),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: widget.member?['status']?.toString() ?? 'Active',
                  items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => widget.member?['status'] = v),
                  decoration: const InputDecoration(labelText: 'Member Status', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info_outline)),
                ),
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
                  items: widget.plans.isEmpty 
                    ? [DropdownMenuItem(value: _plan, child: Text(_plan))]
                    : widget.plans.map((p) => DropdownMenuItem(value: p['name'].toString(), child: Text(p['name'].toString()))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _plan = v!;
                      final selectedPlan = widget.plans.firstWhere((p) => p['name'] == v, orElse: () => {});
                      if (selectedPlan.isNotEmpty) {
                        _priceController.text = selectedPlan['price'].toString().replaceAll(',', '');
                        _updateExpiryDateWithPlan(selectedPlan);
                      }
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
                'joinDate': _joinDate.toIso8601String(),
                'plan': _plan,
                'price': _priceController.text,
                'expiryDate': _expiryDate.toIso8601String(),
                'trainer': _trainerController.text.isEmpty ? 'Self' : _trainerController.text,
                'imagePath': _image?.path,
              };
              if (widget.member != null) {
                memberData['id'] = widget.member!['id'];
                memberData['status'] = widget.member!['status'] ?? 'Active';
                memberData['password'] = _passwordController.text;
              } else {
                memberData['password'] = _passwordController.text;
                memberData['status'] = 'Active';
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

  void _updateExpiryDateWithPlan(Map<String, dynamic> selectedPlan) {
    setState(() {
      final durationStr = selectedPlan['duration'].toString();
      if (durationStr.contains('Month')) {
        _expiryDate = _joinDate.add(Duration(days: 30 * int.parse(durationStr.split(' ')[0])));
      } else if (durationStr.contains('Year')) {
        _expiryDate = _joinDate.add(Duration(days: 365 * int.parse(durationStr.split(' ')[0])));
      } else {
        _expiryDate = _joinDate.add(const Duration(days: 30));
      }
    });
  }
}
