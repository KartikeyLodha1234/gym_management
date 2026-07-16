import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'sidebar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Kartikey Gym Admin');
  final _emailController = TextEditingController(text: 'admin@kartikeygym.com');
  final _gymNameController = TextEditingController(text: 'Kartikey Gym');
  final _addressController = TextEditingController(text: '123 Fitness Street, New Delhi');
  
  File? _profileImage;
  bool _isEditing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'admin_profile.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      setState(() => _profileImage = savedImage);
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
        title: const Text('Admin Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: const Color(0xFF2D6A4F)),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Save logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile Updated Successfully!'), backgroundColor: Colors.green),
                  );
                }
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      drawer: const AppSidebar(currentPage: 'Profile'),
      body: SingleChildScrollView(
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
                  _buildProfileField('Gym Name', _gymNameController, Icons.fitness_center),
                  _buildProfileField('Gym Address', _addressController, Icons.location_on, maxLines: 2),
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
                onTap: () {
                  // Change password logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF2D6A4F)),
                title: const Text('Privacy Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
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
