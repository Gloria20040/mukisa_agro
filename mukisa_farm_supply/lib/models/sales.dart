class Sale {
  final int? id;
  final int productId;
  final int quantityPieces;
  final double sellPrice;
  final double totalAmount;
  final String role; // admin or sales
  final DateTime date;

  Sale({
    this.id,
    required this.productId,
    required this.quantityPieces,
    required this.sellPrice,
    required this.totalAmount,
    required this.role,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'quantity_pieces': quantityPieces,
      'sell_price': sellPrice,
      'total_amount': totalAmount,
      'role': role,
      'date': date.toIso8601String(),
    };
  }
}
