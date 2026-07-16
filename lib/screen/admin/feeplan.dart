import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'plan_data.dart';
import '../../services/firebase_service.dart';

class FeePlanPage extends StatefulWidget {
  const FeePlanPage({super.key});

  @override
  State<FeePlanPage> createState() => _FeePlanPageState();
}

class _FeePlanPageState extends State<FeePlanPage> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshPlans();
  }

  Future<void> _refreshPlans() async {
    setState(() => _isLoading = true);
    final data = await FirebaseService.instance.getAllPlans();
    
    // If no plans in DB, migrate initial plans from PlanData
    if (data.isEmpty) {
      for (var plan in PlanData.plans) {
        await FirebaseService.instance.addPlan({
          'name': plan['name'],
          'price': plan['price'],
          'duration': plan['duration'],
          'features': (plan['features'] as List<String>).join(','),
          'color': (plan['color'] as Color).value,
        });
      }
      final newData = await FirebaseService.instance.getAllPlans();
      setState(() {
        _plans = newData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _plans = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _addOrUpdatePlan(Map<String, dynamic> planData, {String? id}) async {
    if (id != null) {
      await FirebaseService.instance.updatePlan(planData);
    } else {
      await FirebaseService.instance.addPlan(planData);
    }
    _refreshPlans();
  }

  void _deletePlan(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this fee plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseService.instance.deletePlan(id);
              Navigator.pop(context);
              _refreshPlans();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Fee Plans',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: const AppSidebar(currentPage: 'Fee Plans'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gym Membership Plans',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the best plan for your fitness journey',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return _buildPlanCard(plan);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        backgroundColor: const Color(0xFF2D6A4F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showPlanDialog({Map<String, dynamic>? plan}) {
    showDialog(
      context: context,
      builder: (context) => PlanDialog(
        plan: plan,
        onSave: (newData) => _addOrUpdatePlan(newData, id: plan?['id']),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> plan) {
    List<String> features = (plan['features'] as String).split(',');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan['name'], style: TextStyle(color: Color(plan['color']), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${plan['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Duration: ${plan['duration']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...features.map((f) => Text('• $f')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Color(plan['color']),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${plan['price']}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showViewDialog(plan),
                      icon: const Icon(Icons.visibility, size: 20),
                      label: const Text('View'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showPlanDialog(plan: plan),
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                      label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton.icon(
                      onPressed: () => _deletePlan(plan['id'].toString()),
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlanDialog extends StatefulWidget {
  final Map<String, dynamic>? plan;
  final Function(Map<String, dynamic>) onSave;

  const PlanDialog({super.key, this.plan, required this.onSave});

  @override
  State<PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<PlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _featuresController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?['name'] ?? '');
    _priceController = TextEditingController(text: widget.plan?['price'] ?? '');
    _durationController = TextEditingController(text: widget.plan?['duration'] ?? '');
    _featuresController = TextEditingController(text: widget.plan?['features'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan == null ? 'Add New Plan' : 'Edit Plan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Plan Name'),
                validator: (v) => v!.isEmpty ? 'Enter plan name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration (e.g. 1 Month)'),
                validator: (v) => v!.isEmpty ? 'Enter duration' : null,
              ),
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(labelText: 'Features (comma separated)'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Enter at least one feature' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                if (widget.plan != null) 'id': widget.plan!['id'],
                'name': _nameController.text,
                'price': _priceController.text,
                'duration': _durationController.text,
                'features': _featuresController.text,
                'color': widget.plan?['color'] ?? const Color(0xFF2D6A4F).value,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
