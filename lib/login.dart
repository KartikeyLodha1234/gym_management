import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'screen/admin/dashboard.dart';
import 'screen/staff/staff_dashboard.dart';
import 'screen/customer/customer_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // 1. Check Hardcoded Master Admin
      if (email == 'adminkartikey' && password == 'Kartikey@1805') {
        _navigateTo(const DashboardPage());
        return;
      }

      // 2. Check Staff Table
      final staff = await DatabaseHelper.instance.queryAllStaff();
      final staffUser = staff.cast<Map<String, dynamic>?>().firstWhere(
        (s) => s!['email'] == email && s['password'] == password,
        orElse: () => null,
      );

      if (staffUser != null) {
        _navigateTo(StaffDashboard(role: staffUser['role'], userData: staffUser));
        return;
      }

      // 3. Check Members Table (Customers)
      final members = await DatabaseHelper.instance.queryAllMembers();
      final memberUser = members.cast<Map<String, dynamic>?>().firstWhere(
        (m) => m!['email'] == email && m['password'] == password,
        orElse: () => null,
      );

      if (memberUser != null) {
        _navigateTo(CustomerDashboard(userData: memberUser));
        return;
      }

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Email or Password'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateTo(Widget page) {
    setState(() => _isLoading = false);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6EF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const Text('Welcome Back!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
                const Text('Login to Continue', style: TextStyle(fontSize: 18, color: Color(0xFF52796F))),
                const SizedBox(height: 30),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const Icon(Icons.fitness_center, size: 100, color: Color(0xFF2D6A4F)),
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email / Username',
                          filled: true,
                          fillColor: const Color(0xFFD8E2DC).withValues(alpha: 0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: const Color(0xFFD8E2DC).withValues(alpha: 0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF388E3C),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
