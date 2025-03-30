import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String description;
  final String category;
  final double price;
  final double cost;
  final int stock;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    this.isActive = true,
  });

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    double? price,
    double? cost,
    int? stock,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'cost': cost,
      'stock': stock,
      'isActive': isActive,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      cost: map['cost']?.toDouble() ?? 0.0,
      stock: map['stock']?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Product(id: $id, name: $name, description: $description, category: $category, price: $price, cost: $cost, stock: $stock, isActive: $isActive)';
  }
}