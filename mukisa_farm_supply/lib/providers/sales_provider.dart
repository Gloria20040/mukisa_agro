import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class SalesProvider with ChangeNotifier {
  double _todayTotal = 0;

  double get todayTotal => _todayTotal;

  /// Record a sale and reduce stock
  Future<void> sellProduct({
    required int productId,
    required int quantityPieces,
    required double sellPrice,
    required String role, // admin or sales
  }) async {
    final db = await DBHelper.instance.database;

    // 1️⃣ Get product
    final productData = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (productData.isEmpty) {
      throw Exception('Product not found');
    }

    final product = productData.first;
    final int currentQty = product['quantity'] as int;

    // 2️⃣ Check stock
    if (quantityPieces > currentQty) {
      throw Exception('Not enough stock');
    }

    // 3️⃣ Calculate totals
    final double totalAmount = quantityPieces * sellPrice;
    final int newQty = currentQty - quantityPieces;

    // 4️⃣ Insert sale
    await db.insert('sales', {
      'product_id': productId,
      'quantity_pieces': quantityPieces,
      'sell_price': sellPrice,
      'total_amount': totalAmount,
      'role': role,
      'date': DateTime.now().toIso8601String(),
    });

    // 5️⃣ Update stock
    await db.update(
      'products',
      {'quantity': newQty},
      where: 'id = ?',
      whereArgs: [productId],
    );

    _todayTotal += totalAmount;
    notifyListeners();
  }

  /// Load today's sales total
  Future<void> loadTodayTotal() async {
    final db = await DBHelper.instance.database;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await db.rawQuery('''
      SELECT SUM(total_amount) as total
      FROM sales
      WHERE date LIKE ?
    ''', ['$today%']);

    _todayTotal = result.first['total'] == null
        ? 0
        : (result.first['total'] as num).toDouble();

    notifyListeners();
  }
}
