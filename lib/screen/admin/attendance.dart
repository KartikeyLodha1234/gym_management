import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import '../../database_helper.dart';
import 'sidebar.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _allStaff = [];
  List<Map<String, dynamic>> _memberAttendance = [];
  List<Map<String, dynamic>> _staffAttendance = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final members = await DatabaseHelper.instance.queryAllMembers();
    final staff = await DatabaseHelper.instance.queryAllStaff();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final mAttendance = await DatabaseHelper.instance.queryAttendanceByDate(dateStr);
    final sAttendance = await DatabaseHelper.instance.queryStaffAttendanceByDate(dateStr);
    
    setState(() {
      _allMembers = members;
      _allStaff = staff;
      _memberAttendance = mAttendance;
      _staffAttendance = sAttendance;
      _isLoading = false;
    });
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<String?> _capturePhoto(String prefix) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
    return savedImage.path;
  }

  Future<void> _markCheckIn(Map<String, dynamic> user, String userType) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentList = userType == 'Member' ? _memberAttendance : _staffAttendance;
    
    final alreadyIn = currentList.any((a) => a['memberId'].toString() == user['id'].toString() && a['checkOutTime'] == null);
    
    if (alreadyIn) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user['name']} is already checked in!'), backgroundColor: Colors.orange));
      return;
    }

    // Capture verification data
    final photoPath = await _capturePhoto('in_${user['id']}');
    if (photoPath == null) return; // Cancelled

    final position = await _getCurrentLocation();
    if (position == null) return; // Cancelled

    final attendanceData = {
      'memberId': user['id'],
      'memberName': user['name'],
      'date': dateStr,
      'time': DateFormat('hh:mm a').format(DateTime.now()),
      'userType': userType,
      'status': 'Present',
      'checkInPhoto': photoPath,
      'checkInLat': position.latitude,
      'checkInLong': position.longitude,
    };

    await DatabaseHelper.instance.insertAttendance(attendanceData);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checked-in: ${user['name']}'), backgroundColor: Colors.green));
  }

  Future<void> _markCheckOut(Map<String, dynamic> record) async {
    // Capture verification data
    final photoPath = await _capturePhoto('out_${record['memberId']}');
    if (photoPath == null) return;

    final position = await _getCurrentLocation();
    if (position == null) return;

    final checkOutTime = DateFormat('hh:mm a').format(DateTime.now());
    await DatabaseHelper.instance.updateAttendance(int.parse(record['id'].toString()), {
      'checkOutTime': checkOutTime,
      'checkOutPhoto': photoPath,
      'checkOutLat': position.latitude,
      'checkOutLong': position.longitude,
    });
    
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked-out successfully'), backgroundColor: Colors.blue));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Attendance Verification', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2D6A4F),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D6A4F),
          tabs: const [Tab(text: 'Members'), Tab(text: 'Staff')],
        ),
      ),
      drawer: const AppSidebar(currentPage: 'Attendance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceView('Member', _allMembers, _memberAttendance),
                _buildAttendanceView('Staff', _allStaff, _staffAttendance),
              ],
            ),
    );
  }

  Widget _buildAttendanceView(String type, List<Map<String, dynamic>> searchList, List<Map<String, dynamic>> attendanceList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Mark Check-in ($type)'),
          _buildCard([
            Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['name'].toString(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
                return searchList.where((Map<String, dynamic> option) {
                  return option['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                         option['id'].toString().contains(textEditingValue.text);
                });
              },
              onSelected: (user) => _markCheckIn(user, type),
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search $type to Check-in',
                    hintText: 'Camera & Location required',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.camera_alt),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Attendance Log'),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month, color: Color(0xFF2D6A4F)),
                label: Text(DateFormat('dd MMM').format(_selectedDate)),
                onPressed: () async {
                  final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2023), lastDate: DateTime.now());
                  if (picked != null) { setState(() => _selectedDate = picked); _loadData(); }
                },
              ),
            ],
          ),
          
          _buildCard([
            if (attendanceList.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No records found.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendanceList.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final record = attendanceList[index];
                  bool isCheckedOut = record['checkOutTime'] != null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      onTap: () => _showVerificationDetails(record),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: record['checkInPhoto'] != null ? FileImage(File(record['checkInPhoto'])) : null,
                        child: record['checkInPhoto'] == null ? const Icon(Icons.person) : null,
                      ),
                    ),
                    title: Text(record['memberName'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('In: ${record['time']}'),
                        if (isCheckedOut) Text('Out: ${record['checkOutTime']}', style: const TextStyle(color: Colors.blue)),
                      ],
                    ),
                    trailing: !isCheckedOut
                        ? ElevatedButton(
                            onPressed: () => _markCheckOut(record),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                            child: const Text('Check-out'),
                          )
                        : const Icon(Icons.verified, color: Colors.green),
                  );
                },
              ),
          ]),
        ],
      ),
    );
  }

  void _showVerificationDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${record['memberName']} Verification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Check-in Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              if (record['checkInPhoto'] != null) Image.file(File(record['checkInPhoto']), height: 150),
              const SizedBox(height: 10),
              Text('Location: ${record['checkInLat']}, ${record['checkInLong']}'),
              const Divider(),
              if (record['checkOutTime'] != null) ...[
                const Text('Check-out Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                if (record['checkOutPhoto'] != null) Image.file(File(record['checkOutPhoto']), height: 150),
                const SizedBox(height: 10),
                Text('Location: ${record['checkOutLat']}, ${record['checkOutLong']}'),
              ] else 
                const Text('Not yet checked out'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))));
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
