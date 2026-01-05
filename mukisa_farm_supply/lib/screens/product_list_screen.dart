import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import 'add_product_screen.dart';
import 'sales_screen.dart';
import 'role_selection.dart';

class ProductListScreen extends StatefulWidget {
  final String role;
  const ProductListScreen({super.key, required this.role});

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
      body: provider.products.isEmpty
          ? const Center(child: Text('No products yet'))
          : ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (ctx, i) {
                final p = provider.products[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('${p.category} • Qty: ${p.quantity}'),
                  trailing: Text('UGX ${p.sellPrice}'),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.role == 'admin')
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
                  builder: (_) => SalesScreen(role: widget.role),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
