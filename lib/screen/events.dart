import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'dashboard.dart';
import 'member.dart';
import 'feeplan.dart';
import 'payments.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.queryAllEvents();
    setState(() {
      _events = data;
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
        title: const Text('Event Planner', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      drawer: _buildSidebar(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return _buildEventCard(event);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
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
          Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No events planned yet', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tap the + button to create an event', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final date = DateTime.parse(event['date']);
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event['type'],
                    style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteEvent(event['id']),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(event['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(event['time'], style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (event['schedule'] != null && event['schedule'].isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Schedule:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(event['schedule'], style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(int id) async {
    await DatabaseHelper.instance.deleteEvent(id);
    _refreshEvents();
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEventDialog(),
    ).then((_) => _refreshEvents());
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
            ),
            _buildSidebarTile(icon: Icons.grid_view, title: 'Dashboard', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
            }),
            _buildSidebarTile(icon: Icons.people, title: 'Members List', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MemberPage()));
            }),
            _buildSidebarTile(icon: Icons.payment, title: 'Payments', onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PaymentsPage()));
            }),
            _buildSidebarTile(icon: Icons.event, title: 'Event Planner', isSelected: true, onTap: () => Navigator.pop(context)),
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

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _scheduleController = TextEditingController();
  String _selectedType = 'Zumba';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<String> _eventTypes = ['Zumba', 'Yoga', 'CrossFit', 'Bootcamp', 'Marathon', 'Fitness Challenge'];

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Plan New Event', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
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
                  value: _selectedType,
                  items: _eventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                  decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                          child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
                          child: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _scheduleController,
                  decoration: const InputDecoration(labelText: 'Schedule/Details', border: OutlineInputBorder(), hintText: 'Enter event flow...'),
                  maxLines: 3,
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
              await DatabaseHelper.instance.insertEvent({
                'title': _titleController.text,
                'type': _selectedType,
                'date': _selectedDate.toIso8601String(),
                'time': _selectedTime.format(context),
                'schedule': _scheduleController.text,
              });
              if (mounted) Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
          child: const Text('Save Event', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
