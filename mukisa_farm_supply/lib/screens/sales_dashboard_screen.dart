import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'role_selection.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  bool _loading = true;
  double _totalSales = 0;
  int _totalItems = 0;
  int _salesCount = 0;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _salesRows = [];

  @override
  void initState() {
    super.initState();
    _loadStatsForDate(_selectedDate);
  }

  Future<void> _loadStatsForDate(DateTime date) async {
    setState(() {
      _loading = true;
    });

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final db = await DBHelper.instance.database;

    // Totals for the day
    final totalRow = await db.rawQuery(
      'SELECT SUM(total_amount) as total, SUM(quantity_pieces) as items, COUNT(*) as cnt FROM sales WHERE date >= ? AND date < ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final row = totalRow.isNotEmpty ? totalRow.first : {};

    // Individual sales for the day (with product name)
    final rows = await db.rawQuery('''
      SELECT s.*, p.name as product_name
      FROM sales s
      LEFT JOIN products p ON p.id = s.product_id
      WHERE s.date >= ? AND s.date < ?
      ORDER BY s.date DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    setState(() {
      final totalVal = row['total'];
      if (totalVal == null) {
        _totalSales = 0;
      } else if (totalVal is int) {
        _totalSales = totalVal.toDouble();
      } else {
        _totalSales = totalVal as double;
      }

      _totalItems = (row['items'] ?? 0) as int;
      _salesCount = (row['cnt'] ?? 0) as int;
      _salesRows = rows;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadStatsForDate(picked);
    }
  }

  Future<void> _clearSalesForDate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm clear'),
        content: Text('Delete all sales for ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}? This will also restore product stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
    });

    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));
    final db = await DBHelper.instance.database;

    try {
      await db.transaction((txn) async {
        final rows = await txn.rawQuery('SELECT * FROM sales WHERE date >= ? AND date < ?', [start.toIso8601String(), end.toIso8601String()]);
        for (final r in rows) {
          final pid = r['product_id'] as int?;
          final qty = r['quantity_pieces'] as int? ?? 0;
          final id = r['id'] as int?;
          if (pid != null) {
            final prodRows = await txn.query('products', where: 'id = ?', whereArgs: [pid]);
            if (prodRows.isNotEmpty) {
              final current = prodRows.first['quantity'] as int;
              await txn.update('products', {'quantity': current + qty}, where: 'id = ?', whereArgs: [pid]);
            }
          }
          if (id != null) {
            await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
          }
        }
      });

      await _loadStatsForDate(_selectedDate);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sales for date cleared')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing sales: $e')));
    }
  }

  String _timeFromIso(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
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
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
            tooltip: 'Pick date',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadStatsForDate(_selectedDate),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Showing: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.monetization_on, size: 36, color: Colors.green),
                      title: const Text('Total Sales'),
                      subtitle: Text('UGX ${_totalSales.toStringAsFixed(0)}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory, size: 36),
                      title: const Text('Total Items Sold'),
                      subtitle: Text('$_totalItems'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long, size: 36),
                      title: const Text('Number of Sales'),
                      subtitle: Text('$_salesCount'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Admin action: clear sales for selected date
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear sales for this date'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(12)),
                    onPressed: _clearSalesForDate,
                  ),
                  const SizedBox(height: 16),
                  const Text('Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _salesRows.isEmpty
                        ? const Center(child: Text('No sales for this date'))
                        : ListView.builder(
                            itemCount: _salesRows.length,
                            itemBuilder: (ctx, i) {
                              final s = _salesRows[i];
                              final time = s['date'] != null ? _timeFromIso(s['date'] as String) : '';
                              final product = s['product_name'] ?? 'Unknown';
                              final qty = s['quantity_pieces'] ?? 0;
                              final totalAmt = double.parse(s['total_amount'].toString());
                              return ListTile(
                                leading: Text(time),
                                title: Text(product),
                                subtitle: Text('Qty: $qty • Role: ${s['role']}'),
                                trailing: Text('UGX ${totalAmt.toStringAsFixed(0)}'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
