import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../providers/auth_provider.dart';
import 'sales_screen.dart';
import 'sales_list_screen.dart';

class SalesRoleDashboard extends StatefulWidget {
  const SalesRoleDashboard({super.key});

  @override
  State<SalesRoleDashboard> createState() => _SalesRoleDashboardState();
}

class _SalesRoleDashboardState extends State<SalesRoleDashboard> {
  bool _loading = true;
  double _todayTotal = 0;
  int _todayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() { _loading = true; });
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).toIso8601String();
    final db = await DBHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT SUM(total_amount) as total, COUNT(*) as cnt FROM sales WHERE date >= ? AND date < ? AND role = ?',
      [start, end, 'sales'],
    );
    final row = rows.isNotEmpty ? rows.first : {};
    double total = 0;
    if (row['total'] != null) {
      final val = row['total'];
      if (val is int) {
        total = val.toDouble();
      } else {
        total = val as double;
      }
    }
    final cnt = (row['cnt'] ?? 0) as int;
    setState(() { _todayTotal = total; _todayCount = cnt; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard (sales)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadToday,
          ),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.green, size: 36),
                title: const Text('Today\'s Sales (sales)'),
                subtitle: Text('UGX ${_todayTotal.toStringAsFixed(0)} • $_todayCount transactions'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.sell),
              label: const Text('Make Sale'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen(role: 'sales')));
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("Today's Sales"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesListScreen(role: 'sales')));
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
