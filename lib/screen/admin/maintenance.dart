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
  String _filterStatus = 'All'; // All, Pending, In Progress, Completed, Cancelled

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

  List<Map<String, dynamic>> _getFilteredRecords() {
    if (_filterStatus == 'All') return _records;
    return _records.where((r) => r['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRecords();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Maintenance & Inventory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: const AppSidebar(currentPage: 'Maintenance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Maintenance Requests'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          items: ['All', 'Pending', 'In Progress', 'Completed', 'Cancelled']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _filterStatus = v!),
                          decoration: const InputDecoration(labelText: 'Filter Status', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (filtered.isEmpty)
                    const Center(child: Text('No records found for the selected status.', style: TextStyle(color: Colors.grey)))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final record = filtered[index];
                        return _buildMaintenanceCard(record);
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        backgroundColor: const Color(0xFF2D6A4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)));
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> record) {
    Color statusColor;
    switch (record['status']) {
      case 'Pending': statusColor = Colors.orange; break;
      case 'In Progress': statusColor = Colors.blue; break;
      case 'Completed': statusColor = Colors.green; break;
      case 'Cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(record['equipmentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${record['category']} • ${record['serviceType']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(record['status'], style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Reported By', record['reportedBy'] ?? 'N/A'),
                _buildInfoRow('Technician', record['repairedBy'] ?? 'Waiting...'),
                _buildInfoRow('Request Date', DateFormat('dd MMM yyyy').format(DateTime.parse(record['date']))),
                if (record['nextServiceDate'] != null) _buildInfoRow('Next Service', DateFormat('dd MMM yyyy').format(DateTime.parse(record['nextServiceDate']))),
                _buildInfoRow('Cost', "₹${record['cost']}"),
                _buildInfoRow('Parts Used', record['partsUsed'] ?? 'None'),
                const SizedBox(height: 10),
                const Text('Remarks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(record['remarks'] ?? 'No remarks', style: const TextStyle(fontSize: 13)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Update Status'),
                      onPressed: () => _showUpdateStatusDialog(record),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteRecord(record['id']),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
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

  void _showUpdateStatusDialog(Map<String, dynamic> record) {
    String selectedStatus = record['status'];
    final techController = TextEditingController(text: record['repairedBy']);
    final partsController = TextEditingController(text: record['partsUsed']);
    final costController = TextEditingController(text: record['cost'].toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update Maintenance Log'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ['Pending', 'In Progress', 'Completed', 'Cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextField(controller: techController, decoration: const InputDecoration(labelText: 'Technician Name')),
                TextField(controller: partsController, decoration: const InputDecoration(labelText: 'Parts Used (e.g. Belt, Cable)')),
                TextField(controller: costController, decoration: const InputDecoration(labelText: 'Repair Cost (₹)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updated = Map<String, dynamic>.from(record);
                updated['status'] = selectedStatus;
                updated['repairedBy'] = techController.text;
                updated['partsUsed'] = partsController.text;
                updated['cost'] = double.tryParse(costController.text) ?? 0.0;
                await DatabaseHelper.instance.updateMaintenance(updated);
                Navigator.pop(context);
                _refreshRecords();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddMaintenanceDialog extends StatefulWidget {
  const AddMaintenanceDialog({super.key});

  @override
  State<AddMaintenanceDialog> createState() => _AddMaintenanceDialogState();
}

class _AddMaintenanceDialogState extends State<AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _equipController = TextEditingController();
  final _descController = TextEditingController();
  final _staffController = TextEditingController(text: 'Admin');
  
  String _selectedCategory = 'Treadmill';
  String _selectedService = 'Daily Check';
  
  final List<String> _categories = ['Treadmill', 'Bike', 'Cross Trainer', 'Dumbbell/Rack', 'Cable Machine', 'Other'];
  final List<String> _services = ['Daily Check', 'Weekly Check', 'Monthly Service', 'Repair', 'Lubrication', 'Cable Replacement'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Maintenance Request', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
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
                  decoration: const InputDecoration(labelText: 'Equipment Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _equipController,
                  decoration: const InputDecoration(labelText: 'Equipment ID / Name', border: OutlineInputBorder(), hintText: 'e.g. Treadmill #01'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedService = v!),
                  decoration: const InputDecoration(labelText: 'Service Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Problem / Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _staffController,
                  decoration: const InputDecoration(labelText: 'Reported By (Staff Name)', border: OutlineInputBorder()),
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
                'equipmentName': _equipController.text,
                'category': _selectedCategory,
                'serviceType': _selectedService,
                'status': 'Pending',
                'reportedBy': _staffController.text,
                'date': DateTime.now().toIso8601String(),
                'cost': 0.0,
                'remarks': _descController.text,
              });
              if (mounted) Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
