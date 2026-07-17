import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import '../../database_helper.dart';

class CustomerDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CustomerDashboard({super.key, required this.userData});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  bool _isCheckedIn = false;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final records = await DatabaseHelper.instance.queryAttendanceByDate(today);
    final myRecord = records.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r!['memberId'].toString() == widget.userData['id'].toString() && r['checkOutTime'] == null,
      orElse: () => null,
    );
    setState(() {
      _isCheckedIn = myRecord != null;
      _todayAttendance = myRecord;
    });
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _handleAttendance() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return;

    final position = await _getCurrentLocation();
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location verification failed.')));
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${_isCheckedIn ? "out" : "in"}_${widget.userData['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(image.path).copy('${appDir.path}/$fileName');

    if (!_isCheckedIn) {
      // Check-in
      await DatabaseHelper.instance.insertAttendance({
        'memberId': widget.userData['id'],
        'memberName': widget.userData['name'],
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'userType': 'Member',
        'status': 'Present',
        'checkInPhoto': savedImage.path,
        'checkInLat': position.latitude,
        'checkInLong': position.longitude,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked-in Successfully!'), backgroundColor: Colors.green));
    } else {
      // Check-out
      await DatabaseHelper.instance.updateAttendance(_todayAttendance!['id'], {
        'checkOutTime': DateFormat('hh:mm a').format(DateTime.now()),
        'checkOutPhoto': savedImage.path,
        'checkOutLat': position.latitude,
        'checkOutLong': position.longitude,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked-out Successfully!'), backgroundColor: Colors.blue));
    }
    _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final expiryDate = DateTime.parse(widget.userData['expiryDate']);
    final remainingDays = expiryDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('My Fitness Hub'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(remainingDays, expiryDate),
            const SizedBox(height: 30),
            const Text('Verify Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildVerificationCard(),
            const SizedBox(height: 30),
            const Text('Upcoming Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildClassItem('Yoga Session', '07:00 AM', 'Coach Aman'),
            _buildClassItem('Zumba Dance', '06:30 PM', 'Coach Sneha'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(int remainingDays, DateTime expiryDate) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                const Text('MEMBERSHIP STATUS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('$remainingDays Days Left', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Expires: ${DateFormat('dd MMM yyyy').format(expiryDate)}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 40),
          )
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isCheckedIn ? Colors.blue : Colors.orange, width: 2)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_isCheckedIn ? Icons.login : Icons.timer, color: _isCheckedIn ? Colors.blue : Colors.orange),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  _isCheckedIn ? 'Currently in Gym' : 'Not Checked-in Today',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _handleAttendance,
            icon: Icon(_isCheckedIn ? Icons.logout : Icons.camera_alt),
            label: Text(_isCheckedIn ? 'Verify & Check-out' : 'Verify & Check-in'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? Colors.blue : const Color(0xFF2D6A4F),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Camera and Location required for verification', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildClassItem(String name, String time, String coach) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2D6A4F))),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), Text('$time • $coach', style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          TextButton(onPressed: () {}, child: const Text('Book')),
        ],
      ),
    );
  }
}
