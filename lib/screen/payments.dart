import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard.dart';
import 'member.dart';
import 'feeplan.dart';
import '../database_helper.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Member Details
  String _memberName = '';
  String _memberId = '';
  String _membershipPlan = 'Monthly';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));

  // Plan Details
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  double _taxRate = 0.18; // 18% GST default

  // Payment Method
  String _paymentMethod = 'UPI';
  final List<String> _methods = ['UPI', 'Credit/Debit Card', 'Net Banking', 'Cash', 'Wallet'];

  double get _subtotal => double.tryParse(_priceController.text) ?? 0.0;
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _taxAmount => (_subtotal - _discount) * _taxRate;
  double get _totalPayable => (_subtotal - _discount) + _taxAmount;

  List<Map<String, dynamic>> _allMembers = [];
  Map<String, dynamic>? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final data = await DatabaseHelper.instance.queryAllMembers();
    setState(() {
      _allMembers = data;
    });
  }

  void _onMemberSelected(Map<String, dynamic> member) {
    setState(() {
      _selectedMember = member;
      _memberName = member['name'];
      _memberId = member['id'].toString();
      _membershipPlan = member['plan'];
      _expiryDate = DateTime.parse(member['expiryDate']);
      _priceController.text = member['price'].toString().replaceAll(',', '');
    });
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      final paymentData = {
        'memberId': int.tryParse(_memberId),
        'memberName': _memberName,
        'plan': _membershipPlan,
        'price': _subtotal,
        'discount': _discount,
        'tax': _taxAmount,
        'totalPayable': _totalPayable,
        'paymentMethod': _paymentMethod,
        'paymentDate': DateTime.now().toIso8601String(),
        'status': 'Paid'
      };

      await DatabaseHelper.instance.insertPayment(paymentData);
      _showSuccessDialog();
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
        title: const Text('Payments', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: _buildSidebar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Member Details'),
              _buildCard([
                Autocomplete<Map<String, dynamic>>(
                  displayStringForOption: (option) => option['name'],
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    return _allMembers.where((Map<String, dynamic> option) {
                      return option['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                             option['id'].toString().contains(textEditingValue.text);
                    });
                  },
                  onSelected: _onMemberSelected,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Search Member Name or ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please select a member' : null,
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildReadOnlyField('Member ID', _memberId),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildReadOnlyField('Plan', _membershipPlan)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildReadOnlyField('Expiry Date', _memberId.isEmpty ? '' : DateFormat('dd MMM yyyy').format(_expiryDate))),
                  ],
                ),
              ]),

              const SizedBox(height: 20),
              _buildSectionTitle('Plan & Pricing'),
              _buildCard([
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Plan Price (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
                TextFormField(
                  controller: _discountController,
                  decoration: const InputDecoration(labelText: 'Discount (₹)', prefixIcon: Icon(Icons.money_off)),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                ),
                const Divider(),
                _buildSummaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
                _buildSummaryRow('Tax (18%)', '₹${_taxAmount.toStringAsFixed(2)}'),
                _buildSummaryRow('Total Payable', '₹${_totalPayable.toStringAsFixed(2)}', isBold: true),
              ]),

              const SizedBox(height: 20),
              _buildSectionTitle('Payment Method'),
              _buildCard([
                Wrap(
                  spacing: 10,
                  children: _methods.map((method) => ChoiceChip(
                    label: Text(method),
                    selected: _paymentMethod == method,
                    onSelected: (selected) {
                      if (selected) setState(() => _paymentMethod = method);
                    },
                    selectedColor: const Color(0xFF2D6A4F),
                    labelStyle: TextStyle(color: _paymentMethod == method ? Colors.white : Colors.black),
                  )).toList(),
                ),
              ]),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A4F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Process & Save Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      key: Key(value), // Use key to force rebuild when value changes
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      readOnly: true,
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? const Color(0xFF2D6A4F) : Colors.black)),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text('Payment Processed & Saved Successfully!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Reset form
                _selectedMember = null;
                _memberId = '';
                _memberName = '';
                _priceController.clear();
              });
            }, 
            child: const Text('OK')
          )
        ],
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
            _buildSidebarTile(icon: Icons.people, title: 'Members List', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemberPage()));
            }),
            _buildSidebarTile(icon: Icons.payment, title: 'Payments', isSelected: true, onTap: () => Navigator.pop(context)),
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
