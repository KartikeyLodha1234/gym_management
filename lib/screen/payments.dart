import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  List<Map<String, dynamic>> _allPayments = [];
  String _paymentSearchQuery = '';
  final TextEditingController _paymentSearchController = TextEditingController();
  Map<String, dynamic>? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final members = await DatabaseHelper.instance.queryAllMembers();
    final payments = await DatabaseHelper.instance.queryAllPayments();
    setState(() {
      _allMembers = members;
      _allPayments = payments;
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
      _loadData(); // Refresh history
      _showSuccessDialog();
    }
  }

  List<Map<String, dynamic>> _getFilteredPayments() {
    if (_paymentSearchQuery.isEmpty) return _allPayments;
    return _allPayments.where((p) {
      final name = p['memberName'].toString().toLowerCase();
      final id = p['memberId'].toString();
      return name.contains(_paymentSearchQuery.toLowerCase()) || id.contains(_paymentSearchQuery);
    }).toList();
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final filtered = _getFilteredPayments();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Kartikey Gym - Payment History')),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Name', 'Plan', 'Total (₹)', 'Method', 'Date'],
            data: filtered.map((p) => [
              p['memberId'].toString(),
              p['memberName'].toString(),
              p['plan'].toString(),
              p['totalPayable'].toString(),
              p['paymentMethod'].toString(),
              DateFormat('dd MMM yyyy').format(DateTime.parse(p['paymentDate'])),
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Payments'];
    excel.delete('Sheet1');

    sheetObject.appendRow([
      TextCellValue('Member ID'),
      TextCellValue('Member Name'),
      TextCellValue('Plan'),
      TextCellValue('Subtotal'),
      TextCellValue('Discount'),
      TextCellValue('Tax'),
      TextCellValue('Total Payable'),
      TextCellValue('Method'),
      TextCellValue('Date')
    ]);

    final filtered = _getFilteredPayments();
    for (var p in filtered) {
      sheetObject.appendRow([
        IntCellValue(p['memberId'] ?? 0),
        TextCellValue(p['memberName'].toString()),
        TextCellValue(p['plan'].toString()),
        DoubleCellValue(double.parse(p['price'].toString())),
        DoubleCellValue(double.parse(p['discount'].toString())),
        DoubleCellValue(double.parse(p['tax'].toString())),
        DoubleCellValue(double.parse(p['totalPayable'].toString())),
        TextCellValue(p['paymentMethod'].toString()),
        TextCellValue(DateFormat('dd MMM yyyy').format(DateTime.parse(p['paymentDate']))),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/payments_history.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Gym Payments History');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPayments = _getFilteredPayments();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Process New Payment'),
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
                    _buildReadOnlyField('Member Name', _memberName),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildReadOnlyField('Member ID', _memberId)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildReadOnlyField('Plan', _membershipPlan)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildReadOnlyField('Expiry Date', _memberId.isEmpty ? '' : DateFormat('dd MMM yyyy').format(_expiryDate)),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 15),
                    const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Process & Save Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Payment History'),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), onPressed: _exportToPDF),
                    IconButton(icon: const Icon(Icons.table_chart, color: Colors.green), onPressed: _exportToExcel),
                  ],
                ),
              ],
            ),
            
            _buildCard([
              TextField(
                controller: _paymentSearchController,
                onChanged: (v) => setState(() => _paymentSearchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Filter history by Name or ID...',
                  prefixIcon: Icon(Icons.filter_list),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Total (₹)')),
                      DataColumn(label: Text('Method')),
                      DataColumn(label: Text('Date')),
                    ],
                    rows: filteredPayments.map((p) => DataRow(cells: [
                      DataCell(Text(p['memberId'].toString())),
                      DataCell(Text(p['memberName'])),
                      DataCell(Text(p['totalPayable'].toStringAsFixed(2))),
                      DataCell(Text(p['paymentMethod'])),
                      DataCell(Text(DateFormat('dd MMM').format(DateTime.parse(p['paymentDate'])))),
                    ])).toList(),
                  ),
                ),
              ),
            ]),
          ],
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      key: Key('${label}_$value'),
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
