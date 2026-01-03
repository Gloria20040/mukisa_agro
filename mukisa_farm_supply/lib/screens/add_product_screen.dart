import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costController = TextEditingController();
  final _sellController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderController = TextEditingController();
  String _unit = 'Pieces';

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _quantityController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameController.text = p.name;
      _categoryController.text = p.category;
      _costController.text = p.costPrice.toString();
      _sellController.text = p.sellPrice.toString();
      _quantityController.text = p.quantity.toString();
      _reorderController.text = p.reorderLevel.toString();
      _unit = p.unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
    appBar: AppBar(title: Text(isEditing ? 'Edit Product' : 'Add Product')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val!.isEmpty ? 'Enter product name' : null,
            ),
            const SizedBox(height: 12),
            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _categoryController.text.isEmpty
                  ? null
                  : _categoryController.text,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                'Insecticide',
                'Herbicide',
                'Fungicide',
                'Rodenticide',
                'Fertiliser',
                'Farm Tool',
                'Seeds',
                'Other',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => _categoryController.text = v ?? '',
              validator: (val) => (val == null || val.isEmpty) ? 'Select category' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Cost Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter cost price' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sellController,
                  decoration: const InputDecoration(
                    labelText: 'Sell Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter sell price' : null,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter quantity' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    'Kilograms',
                    'Litres',
                    'Pieces',
                  ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _unit = v ?? 'Pieces'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _reorderController,
                  decoration: const InputDecoration(
                    labelText: 'Reorder Level',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter reorder level' : null,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final product = Product(
                      id: widget.product?.id,
                      name: _nameController.text,
                      category: _categoryController.text,
                      costPrice: double.parse(_costController.text),
                      sellPrice: double.parse(_sellController.text),
                      quantity: int.parse(_quantityController.text),
                      unit: _unit,
                      reorderLevel: int.parse(_reorderController.text),
                    );

                    final providerRef =
                        Provider.of<ProductProvider>(context, listen: false);
                    final navigator = Navigator.of(context);

                    if (isEditing) {
                      await providerRef.updateProduct(product);
                    } else {
                      await providerRef.addProduct(product);
                    }

                    if (!mounted) return;

                    navigator.pop(true);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Text(isEditing ? 'Update Product' : 'Add Product'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
