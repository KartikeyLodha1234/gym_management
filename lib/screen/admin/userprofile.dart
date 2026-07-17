import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_service.dart';
import 'sidebar.dart';
import '../../database_helper.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _gymNameController;
  late TextEditingController _addressController;
  
  File? _profileImage;
  bool _isEditing = false;
  late String _role;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _role = AuthService.instance.currentRole ?? 'Admin';
    
    _nameController = TextEditingController(text: user?['name']?.toString() ?? 'Kartikey Gym Admin');
    _emailController = TextEditingController(text: user?['email']?.toString() ?? 'admin@kartikeygym.com');
    _gymNameController = TextEditingController(text: 'Kartikey Gym');
    _addressController = TextEditingController(text: '123 Fitness Street, New Delhi');

    if (user?['imagePath'] != null && File(user!['imagePath'].toString()).existsSync()) {
      _profileImage = File(user['imagePath'].toString());
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      setState(() => _profileImage = savedImage);
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            TextField(controller: newPassController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
            TextField(controller: confirmPassController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (newPassController.text == confirmPassController.text && newPassController.text.isNotEmpty) {
                // Update password logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Changed Successfully!'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    bool _isPrivate = true;
    bool _showEmail = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Privacy Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Private Profile'),
                value: _isPrivate,
                onChanged: (v) => setDialogState(() => _isPrivate = v),
              ),
              SwitchListTile(
                title: const Text('Show Email to Members'),
                value: _showEmail,
                onChanged: (v) => setDialogState(() => _showEmail = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = AuthService.instance.currentUser;
    final role = AuthService.instance.currentRole;

    if (role == 'Admin') {
      if (_profileImage != null) {
        await DatabaseHelper.instance.saveAdminSetting('profile_image', _profileImage!.path);
        AuthService.instance.updateUser({'imagePath': _profileImage!.path});
      }
      await DatabaseHelper.instance.saveAdminSetting('admin_name', _nameController.text);
      AuthService.instance.updateUser({'name': _nameController.text});
    } else if (role == 'Member') {
      final updatedData = Map<String, dynamic>.from(user!);
      updatedData['name'] = _nameController.text;
      if (_profileImage != null) updatedData['imagePath'] = _profileImage!.path;
      
      await DatabaseHelper.instance.updateMember(updatedData);
      AuthService.instance.setUser(updatedData, 'Member');
    } else {
      // Staff (Manager, Trainer, etc)
      final updatedData = Map<String, dynamic>.from(user!);
      updatedData['name'] = _nameController.text;
      if (_profileImage != null) updatedData['imagePath'] = _profileImage!.path;
      
      await DatabaseHelper.instance.updateStaff(updatedData);
      AuthService.instance.setUser(updatedData, updatedData['role']);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
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
        title: Text('$_role Profile', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: const Color(0xFF2D6A4F)),
            onPressed: () async {
              if (_isEditing) {
                await _saveProfile();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      drawer: const AppSidebar(currentPage: 'Profile'),      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF2D6A4F),
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null 
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF2D6A4F)),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileField('Full Name', _nameController, Icons.person),
                  _buildProfileField('Email Address', _emailController, Icons.email),
                  if (_role == 'Admin') ...[
                    _buildProfileField('Gym Name', _gymNameController, Icons.fitness_center),
                    _buildProfileField('Gym Address', _addressController, Icons.location_on, maxLines: 2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!_isEditing) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Color(0xFF2D6A4F)),
                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF2D6A4F)),
                title: const Text('Privacy Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPrivacySettingsDialog,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2D6A4F)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
      ),
    );
  }
}
