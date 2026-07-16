import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database_helper.dart';
import 'sidebar.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.queryAllMaintenance();
    setState(() {
      _records = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Maintenance Log', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppSidebar(currentPage: 'Maintenance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return _buildMaintenanceCard(record);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        backgroundColor: const Color(0xFF2D6A4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No maintenance records', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap + to log equipment repair or service', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record['category'] ?? 'General',
                    style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  '₹${record['cost']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(record['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(record['description'] ?? '', style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(record['date'])),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteRecord(record['id']),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteMaintenance(id);
    _refreshRecords();
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddMaintenanceDialog(),
    ).then((_) => _refreshRecords());
  }
}

class AddMaintenanceDialog extends StatefulWidget {
  const AddMaintenanceDialog({super.key});

  @override
  State<AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _costController = TextEditingController();
  String _selectedCategory = 'Equipment';
  final List<String> _categories = ['Equipment', 'Facility', 'Electrical', 'Plumbing', 'Cleaning', 'Other'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Maintenance', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title / Item Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(labelText: 'Cost (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await DatabaseHelper.instance.insertMaintenance({
                'title': _titleController.text,
                'description': _descController.text,
                'cost': double.tryParse(_costController.text) ?? 0.0,
                'date': DateTime.now().toIso8601String(),
                'category': _selectedCategory,
              });
              if (mounted) Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: const Text('Save Record', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
