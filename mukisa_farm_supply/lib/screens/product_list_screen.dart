import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'add_product_screen.dart';
import 'sales_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // redirect to login if unauthenticated
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mukisa Farm Supply'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                auth.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else if (v == 'change_password') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              } else if (v == 'switch_user') {
                auth.logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            itemBuilder: (_) {
              if (auth.isAdmin) {
                return [
                  const PopupMenuItem(value: 'change_password', child: Text('Change Password')),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ];
              }
              return [
                const PopupMenuItem(value: 'switch_user', child: Text('Switch User / Login as Admin')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: provider.products.isEmpty
          ? const Center(child: Text('No products yet'))
          : ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (ctx, i) {
                final p = provider.products[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('${p.category} • Qty: ${p.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('UGX ${p.sellPrice}'),
                      const SizedBox(width: 8),
                      if (auth.isAdmin) ...[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit product',
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(product: p)));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete product',
                          onPressed: () async {
                            final providerRef = Provider.of<ProductProvider>(context, listen: false);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm delete'),
                                content: Text('Delete product "${p.name}"? This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                            await providerRef.deleteProduct(p.id!);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (auth.isAdmin)
            FloatingActionButton(
              heroTag: 'add',
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'sell',
            child: const Icon(Icons.sell),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SalesScreen(role: auth.currentUser!['role'] as String),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
