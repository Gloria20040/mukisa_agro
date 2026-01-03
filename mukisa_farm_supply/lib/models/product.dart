class Product {
  final int? id;
  final String name;
  final String category;
  final double costPrice;
  final double sellPrice;
  final int quantity;
  final String unit;
  final int reorderLevel;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellPrice,
    required this.quantity,
    required this.unit,
    required this.reorderLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'quantity': quantity,
      'unit': unit,
      'reorder_level': reorderLevel,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      costPrice: map['cost_price'],
      sellPrice: map['sell_price'],
      quantity: map['quantity'],
      unit: map['unit'] ?? 'Pieces',
      reorderLevel: map['reorder_level'],
    );
  }
}
