import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  Future<void> loadProducts() async {
    final db = await DBHelper.instance.database;
    final data = await db.query('products');
    _products = data.map((e) => Product.fromMap(e)).toList();
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
    await db.update(
      'products',
      product.toMap(),
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
}
