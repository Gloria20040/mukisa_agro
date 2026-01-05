import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'sales_dashboard_screen.dart';
import 'role_selection.dart';

class SalesListScreen extends StatefulWidget {
  final String? role;
  const SalesListScreen({super.key, this.role});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final db = await DBHelper.instance.database;

    String sql;
    List args = [];

    if (widget.role == 'sales') {
      // show only today's sales made by sales role
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day).toIso8601String();
      final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).toIso8601String();
      sql = '''
        SELECT s.*, p.name as product_name
        FROM sales s
        LEFT JOIN products p ON p.id = s.product_id
        WHERE s.date >= ? AND s.date < ? AND s.role = ?
        ORDER BY date DESC
      ''';
      args = [start, end, 'sales'];
    } else {
      sql = '''
        SELECT s.*, p.name as product_name
        FROM sales s
        LEFT JOIN products p ON p.id = s.product_id
        ORDER BY date DESC
      ''';
      args = [];
    }

    final rows = await db.rawQuery(sql, args);

    setState(() {
      _sales = rows;
      _loading = false;
    });
  }

  Future<void> _cancelSale(Map<String, dynamic> s) async {
    final id = s['id'] as int?;
    if (id == null) return;

    final messenger = ScaffoldMessenger.of(context);

    // only admin may cancel sales
    if (widget.role != 'admin') {
      messenger.showSnackBar(const SnackBar(content: Text('You are not allowed to cancel sales')));
      return;
    }

    final dateStr = s['date'] as String?;
    final date = dateStr == null ? null : DateTime.tryParse(dateStr)?.toLocal();
    if (date == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Unable to determine sale time')));
      return;
    }

    final diff = DateTime.now().difference(date);
    // allow cancel only within 10 minutes of sale
    if (diff > const Duration(minutes: 10)) {
      messenger.showSnackBar(const SnackBar(content: Text('Sale cannot be cancelled after 10 minutes')));
      return;
    }

    final db = await DBHelper.instance.database;
    await db.transaction((txn) async {
      // restore product quantity
      final qty = s['quantity_pieces'] as int? ?? 0;
      final pid = s['product_id'] as int?;
      if (pid != null) {
        final rows = await txn.query('products', where: 'id = ?', whereArgs: [pid]);
        if (rows.isNotEmpty) {
          final current = rows.first['quantity'] as int;
          await txn.update('products', {'quantity': current + qty}, where: 'id = ?', whereArgs: [pid]);
        }
      }

      await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
    });

    await _loadSales();
    if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Sale cancelled')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SalesDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(child: Text('No sales recorded'))
              : ListView.builder(
                  itemCount: _sales.length,
                  itemBuilder: (ctx, i) {
                    final s = _sales[i];
                    final date = DateTime.tryParse(s['date'] ?? '')?.toLocal();
                    final dateOnly = date == null
                      ? ''
                      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final timeStr = date == null
                      ? ''
                      : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                    String prevDateOnly = '';
                    if (i > 0) {
                      final prevDate = DateTime.tryParse(_sales[i - 1]['date'] ?? '')?.toLocal();
                      if (prevDate != null) {
                        prevDateOnly = '${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}';
                      }
                    }

                    final showHeader = i == 0 || prevDateOnly != dateOnly;

                    final diff = date == null ? const Duration(days: 365) : DateTime.now().difference(date);
                    final canCancel = (widget.role == 'admin') && diff <= const Duration(minutes: 10);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              dateOnly.isEmpty ? 'Unknown date' : dateOnly,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ListTile(
                          title: Text(s['product_name'] ?? 'Unknown'),
                          subtitle: Text('Qty: ${s['quantity_pieces']} • Role: ${s['role']}\n$timeStr'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('UGX ${double.parse(s['total_amount'].toString()).toStringAsFixed(0)}'),
                              const SizedBox(width: 8),
                              if (canCancel)
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _cancelSale(s),
                                  tooltip: 'Cancel sale',
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
