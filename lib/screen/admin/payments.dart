import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'sidebar.dart';
import '../../database_helper.dart';

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
  String _filterStatus = 'All'; // All, Paid, Pending, Defaulters
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
      _memberName = member['name'].toString();
      _memberId = member['id'].toString();
      _membershipPlan = member['plan'].toString();
      _expiryDate = member['expiryDate'] is String ? DateTime.parse(member['expiryDate'].toString()) : member['expiryDate'];
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
      _loadData();
      _showSuccessDialog();
    }
  }

  List<Map<String, dynamic>> _getFilteredPayments() {
    return _allPayments.where((p) {
      final name = p['memberName'].toString().toLowerCase();
      final id = p['memberId'].toString();
      final status = p['status'].toString();
      
      bool matchesSearch = name.contains(_paymentSearchQuery.toLowerCase()) || id.contains(_paymentSearchQuery);
      bool matchesStatus = _filterStatus == 'All' || status == _filterStatus;
      
      if (_filterStatus == 'Defaulters') {
        return matchesSearch && status != 'Paid';
      }
      
      return matchesSearch && matchesStatus;
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
            headers: ['ID', 'Name', 'Total (₹)', 'Method', 'Status', 'Date'],
            data: filtered.map((p) => [
              p['memberId'].toString(),
              p['memberName'].toString(),
              p['totalPayable'].toString(),
              p['paymentMethod'].toString(),
              p['status'].toString(),
              DateFormat('dd MMM yyyy').format(DateTime.parse(p['paymentDate'].toString())),
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
      TextCellValue('ID'),
      TextCellValue('Name'),
      TextCellValue('Plan'),
      TextCellValue('Total'),
      TextCellValue('Method'),
      TextCellValue('Status'),
      TextCellValue('Date')
    ]);

    for (var p in _getFilteredPayments()) {
      sheetObject.appendRow([
        IntCellValue(int.tryParse(p['memberId'].toString()) ?? 0),
        TextCellValue(p['memberName'].toString()),
        TextCellValue(p['plan'].toString()),
        DoubleCellValue(double.tryParse(p['totalPayable'].toString()) ?? 0.0),
        TextCellValue(p['paymentMethod'].toString()),
        TextCellValue(p['status'].toString()),
        TextCellValue(DateFormat('dd MMM yyyy').format(DateTime.parse(p['paymentDate'].toString()))),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/filtered_payments.xlsx');
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
      drawer: const AppSidebar(currentPage: 'Payments'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard([
              _buildSectionTitle('Process Payment'),
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => option['name'].toString(),
                optionsBuilder: (textValue) => _allMembers.where((m) => m['name'].toString().toLowerCase().contains(textValue.text.toLowerCase())),
                onSelected: _onMemberSelected,
                fieldViewBuilder: (ctx, ctrl, node, onSub) => TextFormField(controller: ctrl, focusNode: node, decoration: const InputDecoration(labelText: 'Search Member', prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
              ),
              const SizedBox(height: 15),
              _buildReadOnlyField('Member Name', _memberName),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField('ID', _memberId)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildReadOnlyField('Plan', _membershipPlan)),
                ],
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              _buildSummaryRow('Total Payable (incl. GST)', '₹${_totalPayable.toStringAsFixed(2)}', isBold: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F), minimumSize: const Size.fromHeight(50)),
                child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
              ),
            ]),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _paymentSearchQuery = v),
                      decoration: const InputDecoration(hintText: 'Filter by ID/Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.filter_alt)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _filterStatus,
                    items: ['All', 'Paid', 'Defaulters'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _filterStatus = v!),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: filteredPayments.map((p) => DataRow(cells: [
                    DataCell(Text(p['memberId'].toString())),
                    DataCell(Text(p['memberName'].toString())),
                    DataCell(Text('₹${p['totalPayable']}')),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: p['status'].toString() == 'Paid' ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(10)),
                      child: Text(p['status'].toString(), style: TextStyle(color: p['status'].toString() == 'Paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    )),
                    DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () async {
                      await DatabaseHelper.instance.deletePayment(p['id']);
                      _loadData();
                    })),
                  ])).toList(),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))));
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(key: Key('${label}_$value'), initialValue: value, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), readOnly: true);
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(color: const Color(0xFF2D6A4F), fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
    ]);
  }

  void _showSuccessDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Icon(Icons.check_circle, color: Colors.green, size: 50), content: const Text('Payment Saved Successfully!'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]));
  }
}
