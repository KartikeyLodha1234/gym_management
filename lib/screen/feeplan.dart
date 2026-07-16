import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'member.dart';
import 'plan_data.dart';
import 'payments.dart';
import 'events.dart';

class FeePlanPage extends StatefulWidget {
  const FeePlanPage({super.key});

  @override
  State<FeePlanPage> createState() => _FeePlanPageState();
}

class _FeePlanPageState extends State<FeePlanPage> {
  void _addOrUpdatePlan(Map<String, dynamic> plan, {int? index}) {
    setState(() {
      if (index != null) {
        PlanData.plans[index] = plan;
      } else {
        PlanData.plans.add(plan);
      }
    });
  }

  void _deletePlan(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this fee plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => PlanData.plans.removeAt(index));
              Navigator.pop(context);
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
      drawer: _buildSidebar(context),
      body: SingleChildScrollView(
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
              itemCount: PlanData.plans.length,
              itemBuilder: (context, index) {
                final plan = PlanData.plans[index];
                return _buildPlanCard(plan, index);
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

  void _showPlanDialog({Map<String, dynamic>? plan, int? index}) {
    showDialog(
      context: context,
      builder: (context) => PlanDialog(
        plan: plan,
        onSave: (newPlan) => _addOrUpdatePlan(newPlan, index: index),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plan['name'], style: TextStyle(color: plan['color'], fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₹${plan['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Duration: ${plan['duration']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(plan['features'] as List<String>).map((f) => Text('• $f')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
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
              color: plan['color'],
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
                      onPressed: () => _showPlanDialog(plan: plan, index: index),
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                      label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                    ),
                    TextButton.icon(
                      onPressed: () => _deletePlan(index),
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
            _buildSidebarTile(
              icon: Icons.grid_view,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.people,
              title: 'Members List',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemberPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.payment,
              title: 'Payments',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.event,
              title: 'Event Planner',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EventsPage()));
              },
            ),
            _buildSidebarTile(
              icon: Icons.receipt_long,
              title: 'Fee Plans',
              isSelected: true,
              onTap: () => Navigator.pop(context),
            ),
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
    _featuresController = TextEditingController(text: (widget.plan?['features'] as List<String>?)?.join(', ') ?? '');
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
                'name': _nameController.text,
                'price': _priceController.text,
                'duration': _durationController.text,
                'features': _featuresController.text.split(',').map((e) => e.trim()).toList(),
                'color': widget.plan?['color'] ?? const Color(0xFF2D6A4F),
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
