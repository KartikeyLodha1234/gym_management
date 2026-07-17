import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database_helper.dart';

class CustomerDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CustomerDashboard({super.key, required this.userData});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  bool _isCheckedIn = false;
  Map<String, dynamic>? _todayAttendance;
  List<Map<String, dynamic>> _attendanceHistory = [];
  List<Map<String, dynamic>> _paymentHistory = [];
  int _monthlyAttendanceCount = 0;
  Map<String, dynamic>? _lastPayment;
  bool _isLoading = true;

  // Profile controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isEditingProfile = false;
  File? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _phoneController = TextEditingController(text: widget.userData['mobile']);
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final memberId = widget.userData['id'].toString();

    // 1. Attendance Data
    final allAttendance = await DatabaseHelper.instance.queryAllAttendance();
    final myAttendance = allAttendance.where((a) => a['memberId'].toString() == memberId).toList();
    
    final myTodayRecord = myAttendance.firstWhere(
      (r) => r['date'] == today && r['checkOutTime'] == null,
      orElse: () => {},
    );

    final myMonthlyCount = myAttendance.where((a) => a['date'].toString().startsWith(currentMonth)).length;

    // 2. Payment Data
    final allPayments = await DatabaseHelper.instance.queryAllPayments();
    final myPayments = allPayments.where((p) => p['memberId'].toString() == memberId).toList();
    myPayments.sort((a, b) => b['paymentDate'].toString().compareTo(a['paymentDate'].toString()));

    setState(() {
      _attendanceHistory = myAttendance;
      _paymentHistory = myPayments;
      _isCheckedIn = myTodayRecord.isNotEmpty;
      _todayAttendance = myTodayRecord.isNotEmpty ? myTodayRecord : null;
      _monthlyAttendanceCount = myMonthlyCount;
      if (myPayments.isNotEmpty) _lastPayment = myPayments.first;
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
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F))));

    final List<Widget> pages = [
      _buildHomeView(),
      _buildAttendanceView(),
      _buildPaymentView(),
      _buildSupportView(),
      _buildProfileView(),
    ];

    final titles = ['Home', 'Attendance History', 'Payments', 'Support', 'My Profile'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        actions: [
          if (_currentIndex == 4)
            IconButton(
              icon: Icon(_isEditingProfile ? Icons.save : Icons.edit),
              onPressed: () {
                setState(() {
                  if (_isEditingProfile) {
                    // Save logic
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
                  }
                  _isEditingProfile = !_isEditingProfile;
                });
              },
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacementNamed(context, '/')),
        ],
      ),
      drawer: _buildDrawer(),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D6A4F),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_support_outlined), activeIcon: Icon(Icons.contact_support), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2D6A4F)),
            currentAccountPicture: CircleAvatar(
              backgroundImage: (widget.userData['imagePath'] != null && File(widget.userData['imagePath']).existsSync())
                  ? FileImage(File(widget.userData['imagePath']))
                  : null,
              child: widget.userData['imagePath'] == null ? const Icon(Icons.person, size: 40) : null,
            ),
            accountName: Text(widget.userData['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('ID: #${widget.userData['id']}'),
          ),
          _buildDrawerTile(0, 'Dashboard', Icons.dashboard),
          _buildDrawerTile(1, 'Attendance History', Icons.history),
          _buildDrawerTile(2, 'Payment Records', Icons.receipt_long),
          _buildDrawerTile(3, 'Contact Support', Icons.support_agent),
          _buildDrawerTile(4, 'My Profile', Icons.person_outline),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _currentIndex == index ? const Color(0xFF2D6A4F) : Colors.grey),
      title: Text(title, style: TextStyle(color: _currentIndex == index ? const Color(0xFF2D6A4F) : Colors.black87, fontWeight: _currentIndex == index ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildHomeView() {
    final expiryDate = DateTime.parse(widget.userData['expiryDate']);
    final joinDate = DateTime.parse(widget.userData['joinDate']);
    final remainingDays = expiryDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildMembershipCard(joinDate, expiryDate, remainingDays),
          const SizedBox(height: 20),
          _buildAttendanceQuickCard(),
          const SizedBox(height: 40),
          _buildCopyright(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCopyright() {
    return const Column(
      children: [
        Text(
          '© 2026 Kartikey Gym | All Rights Reserved',
          style: TextStyle(color: Colors.grey, fontSize: 10),
        ),
        Text(
          'Designed & Developed by Kartikey',
          style: TextStyle(
            color: Color(0xFF2D6A4F), 
            fontSize: 11, 
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage: (widget.userData['imagePath'] != null && File(widget.userData['imagePath']).existsSync()) ? FileImage(File(widget.userData['imagePath'])) : null,
            child: widget.userData['imagePath'] == null ? const Icon(Icons.person, color: Color(0xFF2D6A4F)) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userData['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Member ID: #${widget.userData['id']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(widget.userData['mobile'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF409F7A)]), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MEMBERSHIP', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: Text(widget.userData['status'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 15),
          Text(widget.userData['plan'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateInfo('Started', DateFormat('dd MMM yy').format(join)),
              _buildDateInfo('Expires', DateFormat('dd MMM yy').format(expiry)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$remaining', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Days Left', style: TextStyle(color: Colors.white70, fontSize: 9)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      Text(date, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildAttendanceQuickCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatMini('Check-in', _todayAttendance?['time'] ?? '--:--'),
              _buildStatMini('Check-out', _todayAttendance?['checkOutTime'] ?? '--:--'),
              _buildStatMini('Monthly', '$_monthlyAttendanceCount Days'),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _handleAttendance,
            icon: Icon(_isCheckedIn ? Icons.logout : Icons.camera_alt, size: 18),
            label: Text(_isCheckedIn ? 'Verify & Check-out' : 'Verify & Check-in'),
            style: ElevatedButton.styleFrom(backgroundColor: _isCheckedIn ? Colors.orange : const Color(0xFF2D6A4F), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String label, String value) {
    return Column(children: [Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]);
  }

  Widget _buildAttendanceView() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _attendanceHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = _attendanceHistory[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1), child: const Icon(Icons.check, color: Color(0xFF2D6A4F))),
                  title: Text(DateFormat('dd MMMM yyyy').format(DateTime.parse(record['date'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('In: ${record['time']} • Out: ${record['checkOutTime'] ?? "Pending"}'),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildCopyright(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.1))),
            child: Column(
              children: [
                _buildInfoRow('Next Due Date', DateFormat('dd MMM yyyy').format(DateTime.parse(widget.userData['expiryDate']))),
                _buildInfoRow('Due Amount', '₹${widget.userData['price']}'),
                _buildInfoRow('Last Payment', _lastPayment != null ? '₹${_lastPayment!['totalPayable']} on ${DateFormat('dd MMM').format(DateTime.parse(_lastPayment!['paymentDate']))}' : 'No record'),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ..._paymentHistory.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.paid, color: Colors.green),
              title: Text('₹${p['totalPayable']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.parse(p['paymentDate']))),
              trailing: Text(p['paymentMethod'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          )).toList(),
          const SizedBox(height: 30),
          _buildCopyright(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSupportView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildSupportCard('Contact Gym', 'General inquiries and billing', '9352671104', Icons.business, Colors.blue),
          const SizedBox(height: 15),
          _buildSupportCard('Contact Trainer', 'Workout and diet related help', '9664153249', Icons.person, Colors.orange),
          const SizedBox(height: 40),
          _buildCopyright(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSupportCard(String title, String desc, String number, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactAction(number, 'Call'),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactAction(number, 'WhatsApp'),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _contactAction(String number, String type) async {
    final Uri url = type == 'Call' ? Uri.parse('tel:$number') : Uri.parse('https://wa.me/91$number');
    if (await canLaunchUrl(url)) await launchUrl(url);
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

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.1),
                  backgroundImage: _newProfileImage != null 
                    ? FileImage(_newProfileImage!) 
                    : (widget.userData['imagePath'] != null && File(widget.userData['imagePath']).existsSync())
                        ? FileImage(File(widget.userData['imagePath']))
                        : null,
                  child: (_newProfileImage == null && widget.userData['imagePath'] == null) ? const Icon(Icons.person, size: 60, color: Color(0xFF2D6A4F)) : null,
                ),
                if (_isEditingProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2D6A4F),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) setState(() => _newProfileImage = File(image.path));
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildEditableField('Full Name', _nameController, Icons.person),
          _buildEditableField('Mobile Number', _phoneController, Icons.phone),
          _buildEditableField('Email Address', _emailController, Icons.email),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Color(0xFF2D6A4F)),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Password change logic
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF2D6A4F)),
            title: const Text('Privacy Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        enabled: _isEditingProfile,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2D6A4F)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
