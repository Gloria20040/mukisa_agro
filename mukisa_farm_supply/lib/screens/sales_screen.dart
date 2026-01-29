import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../database/db_helper.dart';
import '../models/product.dart';
import 'role_selection.dart';

class SalesScreen extends StatefulWidget {
  final String role; // admin or sales
  const SalesScreen({super.key, required this.role});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  Product? selectedProduct;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  bool _controllerListenerAdded = false;
  double total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  void calculateTotal() {
    if (selectedProduct == null || _qtyController.text.isEmpty) {
      setState(() => total = 0);
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? selectedProduct!.sellPrice;
    setState(() {
      total = qty * price;
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PRODUCT AUTOCOMPLETE (type to filter)
            Autocomplete<Product>(
              displayStringForOption: (p) => p.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                final q = textEditingValue.text.toLowerCase();
                if (q.isEmpty) {
                  return productProvider.products;
                }
                return productProvider.products.where((p) => p.name.toLowerCase().contains(q));
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                if (!_controllerListenerAdded) {
                  controller.addListener(() {
                    if (selectedProduct != null && controller.text != selectedProduct!.name) {
                      setState(() {
                        selectedProduct = null;
                        calculateTotal();
                      });
                    }
                  });
                  _controllerListenerAdded = true;
                }

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Select Product',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Product option = options.elementAt(index);
                          return ListTile(
                            title: Text(option.name),
                            subtitle: Text('Stock: ${option.quantity} • UGX ${option.sellPrice.toStringAsFixed(0)}'),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (Product selection) {
                setState(() {
                  selectedProduct = selection;
                  _priceController.text = selection.sellPrice.toStringAsFixed(0);
                  calculateTotal();
                });
              },
            ),

            const SizedBox(height: 16),

            // QUANTITY INPUT
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (pieces)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => calculateTotal(),
            ),

            const SizedBox(height: 16),

            // PRICE INPUT (editable for discounts)
            if (selectedProduct != null)
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit Price (UGX) - editable for discounts',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => calculateTotal(),
              ),

            if (selectedProduct != null) const SizedBox(height: 16),

            // TOTAL
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: UGX ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SELL BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sell),
                label: const Text('Complete Sale'),
                onPressed: () async {
                  if (selectedProduct == null || _qtyController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fill all fields')),
                    );
                    return;
                  }

                  final qty = int.tryParse(_qtyController.text) ?? 0;
                  if (qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter a valid quantity')),
                    );
                    return;
                  }

                  if (selectedProduct!.quantity < qty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient stock')),
                    );
                    return;
                  }

                  // capture navigator and messenger now to avoid using BuildContext after awaits
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  try {
                    final db = await DBHelper.instance.database;

                    await db.transaction((txn) async {
                      final rows = await txn.query(
                        'products',
                        where: 'id = ?',
                        whereArgs: [selectedProduct!.id],
                      );

                      if (rows.isEmpty) throw Exception('Product not found');

                      final currentQty = rows.first['quantity'] as int;
                      if (currentQty < qty) throw Exception('Insufficient stock');

                      final price = double.tryParse(_priceController.text) ?? selectedProduct!.sellPrice;
                      final totalAmount = qty * price;

                      await txn.insert('sales', {
                        'product_id': selectedProduct!.id,
                        'quantity_pieces': qty,
                        'sell_price': price,
                        'total_amount': totalAmount,
                        'role': widget.role,
                        'date': DateTime.now().toIso8601String(),
                      });

                      await txn.update(
                        'products',
                        {'quantity': currentQty - qty},
                        where: 'id = ?',
                        whereArgs: [selectedProduct!.id],
                      );
                    });

                    await productProvider.loadProducts();

                    if (!mounted) return;

                    messenger.showSnackBar(
                      const SnackBar(content: Text('Sale completed')),
                    );

                    navigator.pop();
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
