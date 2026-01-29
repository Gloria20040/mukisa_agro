import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'product_list_screen.dart';
import 'sales_list_screen.dart';
import 'sales_dashboard_screen.dart';
import 'sales_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'change_password') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              } else if (v == 'logout') {
                auth.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'change_password', child: Text('Change Password')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('Welcome, ${auth.currentUser?['username'] ?? 'admin'}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory_2),
              label: const Text('Manage Products'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
            ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.group),
                label: const Text('Manage Users'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.sell),
              label: const Text('Make Sale'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen(role: 'admin'))),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Sales'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesListScreen())),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.bar_chart),
              label: const Text('Reports'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesDashboardScreen())),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ),
            const SizedBox(height: 8),
            Text('Logged in as: ${auth.currentUser?['role']?.toString().toUpperCase() ?? 'ADMIN'}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
