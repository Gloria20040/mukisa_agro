import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final db = await DBHelper.instance.database;
    final rows = await db.query('users', columns: ['id', 'username', 'role']);
    setState(() {
      _users = rows;
      _loading = false;
    });
  }

  Future<void> _changePassword(int userId, String username) async {
    final formKey = GlobalKey<FormState>();
    final pwCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set password for $username'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pwCtrl,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confCtrl,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
                validator: (v) => v != pwCtrl.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (formKey.currentState?.validate() != true) return;
            Navigator.of(ctx).pop(true);
          }, child: const Text('Set')),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;
    final ok = await Provider.of<AuthProvider>(context, listen: false).adminSetPassword(userId, pwCtrl.text);
    if (ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update password')));
    }
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) {
                final u = _users[i];
                return ListTile(
                  title: Text(u['username'] ?? ''),
                  subtitle: Text('Role: ${u['role'] ?? ''}'),
                  trailing: TextButton(
                    onPressed: () => _changePassword(u['id'] as int, u['username'] as String),
                    child: const Text('Change password'),
                  ),
                );
              },
            ),
    );
  }
}
