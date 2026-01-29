import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  List<Product> get products => _products;
  List<Product> get filteredProducts =>
      _filteredProducts.isEmpty ? _products : _filteredProducts;

  Future<void> loadProducts() async {
    final db = await DBHelper.instance.database;
    final data = await db.query('products');
    _products = data.map((e) => Product.fromMap(e)).toList();
    // initialize filtered list
    _filteredProducts = List<Product>.from(_products);
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final db = await DBHelper.instance.database;
    await db.insert('products', product.toMap());
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null) return;
    final db = await DBHelper.instance.database;
    // Remove 'id' from the map to avoid attempting to update the primary key.
    final values = Map<String, dynamic>.from(product.toMap());
    values.remove('id');
    await db.update(
      'products',
      values,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await loadProducts();
  }

  Future<void> deleteProduct(int id) async {
    final db = await DBHelper.instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    await loadProducts();
  }

  /// Filter products by [query] (case-insensitive). Pass empty string to clear filter.
  void filterProducts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredProducts = List<Product>.from(_products);
    } else {
      _filteredProducts = _products
          .where((p) => p.name.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }

  void clearFilter() {
    _filteredProducts = List<Product>.from(_products);
    notifyListeners();
  }
}
