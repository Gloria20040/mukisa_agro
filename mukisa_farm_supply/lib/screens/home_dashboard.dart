import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import 'sales_list_screen.dart';
import 'sales_dashboard_screen.dart';
import 'sales_screen.dart';
import 'role_selection.dart';

class HomeDashboardScreen extends StatelessWidget {
  final String role;
  const HomeDashboardScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mukisa Farm Supply'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Welcome',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mukisa Farm Supply',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Role: ${role.toUpperCase()}', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // sale button (available to both roles)
            ElevatedButton.icon(
              icon: const Icon(Icons.flash_on),
              label: const Text('Make Sale'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SalesScreen(role: role)),
                );
              },
            ),
            const SizedBox(height: 20),

            // Sales role: quick access to today's sales list
            if (role == 'sales')
              ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text("Today's Sales"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SalesListScreen(role: 'sales')),
                  );
                },
              ),

            // Admin-only actions
            if (role == 'admin') ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Sales'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SalesListScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.inventory_2),
                label: const Text('Products'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductListScreen(role: role)),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart),
                label: const Text('Reports'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SalesDashboardScreen()),
                  );
                },
              ),
            ],
            const Spacer(),
            Text(
              'Logged in as: ${role.toUpperCase()}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
