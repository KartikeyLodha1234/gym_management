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
  int _monthlyAttendance = 0;
  Map<String, dynamic>? _lastPayment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final memberId = widget.userData['id'].toString();

    // 1. Check Today's Check-in/out
    final todayRecords = await DatabaseHelper.instance.queryAttendanceByDate(today);
    final myTodayRecord = todayRecords.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r!['memberId'].toString() == memberId && r['checkOutTime'] == null,
      orElse: () => null,
    );

    // 2. Total Attendance This Month
    final allAttendance = await DatabaseHelper.instance.queryAllAttendance();
    final myMonthlyAttendance = allAttendance.where((a) => 
      a['memberId'].toString() == memberId && 
      a['date'].toString().startsWith(currentMonth)
    ).length;

    // 3. Last Payment
    final allPayments = await DatabaseHelper.instance.queryAllPayments();
    final myPayments = allPayments.where((p) => p['memberId'].toString() == memberId).toList();
    if (myPayments.isNotEmpty) {
      myPayments.sort((a, b) => b['paymentDate'].toString().compareTo(a['paymentDate'].toString()));
      _lastPayment = myPayments.first;
    }

    setState(() {
      _isCheckedIn = myTodayRecord != null;
      _todayAttendance = myTodayRecord;
      _monthlyAttendance = myMonthlyAttendance;
      _isLoading = false;
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
    } else {
      await DatabaseHelper.instance.updateAttendance(_todayAttendance!['id'], {
        'checkOutTime': DateFormat('hh:mm a').format(DateTime.now()),
        'checkOutPhoto': savedImage.path,
        'checkOutLat': position.latitude,
        'checkOutLong': position.longitude,
      });
    }
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F))));

    final expiryDate = DateTime.parse(widget.userData['expiryDate']);
    final joinDate = DateTime.parse(widget.userData['joinDate']);
    final remainingDays = expiryDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text('Member Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacementNamed(context, '/')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildMembershipCard(joinDate, expiryDate, remainingDays),
            const SizedBox(height: 20),
            _buildAttendanceSection(),
            const SizedBox(height: 20),
            _buildPaymentSection(expiryDate),
            const SizedBox(height: 20),
            _buildWorkoutSection(),
            const SizedBox(height: 20),
            _buildSupportSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final imagePath = widget.userData['imagePath']?.toString();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1),
            backgroundImage: (imagePath != null && File(imagePath).existsSync()) ? FileImage(File(imagePath)) : null,
            child: (imagePath == null || !File(imagePath).existsSync()) ? const Icon(Icons.person, size: 40, color: Color(0xFF2D6A4F)) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userData['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Member ID: #${widget.userData['id']}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(widget.userData['mobile'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(DateTime join, DateTime expiry, int remaining) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF409F7A)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MEMBERSHIP', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text(widget.userData['status'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(widget.userData['plan'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo('Started', DateFormat('dd MMM yyyy').format(join)),
              _buildDateInfo('Expires', DateFormat('dd MMM yyyy').format(expiry)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$remaining', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Days Left', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(date, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAttendanceSection() {
    return _buildSectionCard(
      title: 'Attendance',
      icon: Icons.calendar_month,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem('Check-in', _todayAttendance?['time'] ?? '--:--'),
            _buildStatItem('Check-out', _todayAttendance?['checkOutTime'] ?? '--:--'),
            _buildStatItem('Monthly', '$_monthlyAttendance Days'),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _handleAttendance,
          icon: Icon(_isCheckedIn ? Icons.logout : Icons.camera_alt, size: 18),
          label: Text(_isCheckedIn ? 'Verify & Check-out' : 'Verify & Check-in'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCheckedIn ? Colors.orange : const Color(0xFF2D6A4F),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(DateTime expiry) {
    return _buildSectionCard(
      title: 'Payments',
      icon: Icons.payments_outlined,
      children: [
        _buildInfoRow('Last Payment', _lastPayment != null ? '₹${_lastPayment!['totalPayable']} on ${DateFormat('dd MMM').format(DateTime.parse(_lastPayment!['paymentDate']))}' : 'No record'),
        _buildInfoRow('Next Due Date', DateFormat('dd MMM yyyy').format(expiry)),
        _buildInfoRow('Due Amount', '₹${widget.userData['price']}'),
        const Divider(),
        TextButton(onPressed: () {}, child: const Text('View Payment History', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildWorkoutSection() {
    return _buildSectionCard(
      title: 'Workout',
      icon: Icons.fitness_center,
      children: [
        _buildInfoRow('Trainer', widget.userData['trainer'] ?? 'Self'),
        _buildInfoRow('Plan', widget.userData['plan']),
        _buildInfoRow('Today\'s Goal', 'Chest & Triceps'),
        const SizedBox(height: 10),
        const LinearProgressIndicator(value: 0.4, backgroundColor: Color(0xFFE8F5E9), color: Color(0xFF2D6A4F)),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSectionCard(
      title: 'Support',
      icon: Icons.help_outline,
      children: [
        Row(
          children: [
            Expanded(child: _buildSupportButton('Contact Gym', Icons.business, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildSupportButton('Contact Trainer', Icons.person, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 25),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSupportButton(String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey[200]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
