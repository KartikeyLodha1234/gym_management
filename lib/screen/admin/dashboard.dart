import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database_helper.dart';
import 'sidebar.dart';
import 'events.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalMembers = 0;
  int _activeMembers = 0;
  int _totalStaff = 0;
  List<Map<String, dynamic>> _todayEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final members = await DatabaseHelper.instance.queryAllMembers();
      final staff = await DatabaseHelper.instance.queryAllStaff();
      final events = await DatabaseHelper.instance.queryAllEvents();
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      setState(() {
        _totalMembers = members.length;
        _activeMembers = members.where((m) => m['status'] == 'Active').length;
        _totalStaff = staff.length;
        _todayEvents = events.where((e) => e['date'].startsWith(today)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D6A4F)),
        title: const Text('Gym Dashboard', style: TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      drawer: const AppSidebar(currentPage: 'Dashboard'),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatCard('Members', '$_totalMembers', Icons.people, Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('Active', '$_activeMembers', Icons.check_circle, Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('Staff', '$_totalStaff', Icons.badge, Colors.orange),
                    ],
                  ),
                  
                  const SizedBox(height: 25),
                  const Text('Member Registration Growth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                  const SizedBox(height: 12),
                  _buildChartContainer(
                    LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 7), FlSpot(4, 5), FlSpot(5, 8), FlSpot(6, 6)],
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text('Workout Activity Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                  const SizedBox(height: 12),
                  _buildChartContainer(
                    BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.green, width: 15)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.green, width: 15)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.green, width: 15)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.green, width: 15)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.green, width: 15)]),
                          BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 18, color: Colors.green, width: 15)]),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Planner", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsPage())),
                        child: const Text('View All', style: TextStyle(color: Color(0xFF2D6A4F))),
                      ),
                    ],
                  ),
                  
                  if (_todayEvents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        children: [
                          Icon(Icons.event_available, color: Colors.grey[300], size: 40),
                          const SizedBox(height: 10),
                          const Text('No events scheduled for today.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ..._todayEvents.map((e) => _buildEventItem(e)),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D6A4F))),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer(Widget chart) {
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: chart,
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fitness_center, color: Color(0xFF2D6A4F), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${event['type']} • ${event['time']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
