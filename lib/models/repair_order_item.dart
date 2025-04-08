import 'package:electro_workshop/models/product.dart';

class RepairOrderItem {
  final String id;
  final String repairOrderId;
  final String? productId;
  final String deviceType;
  final String brand;
  final String model;
  final String? serialNumber;
  final String problemDescription;
  final List<String> accessories;
  final int quantity;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional reference to related product
  final Product? product;

  RepairOrderItem({
    required this.id,
    required this.repairOrderId,
    this.productId,
    required this.deviceType,
    required this.brand,
    required this.model,
    this.serialNumber,
    required this.problemDescription,
    required this.accessories,
    required this.quantity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory RepairOrderItem.fromJson(Map<String, dynamic> json) {
    List<String> accessoriesList = [];
    if (json['accessories'] != null) {
      accessoriesList = List<String>.from(json['accessories']);
    }

    return RepairOrderItem(
      id: json['id'],
      repairOrderId: json['repairOrderId'],
      productId: json['productId'],
      deviceType: json['deviceType'],
      brand: json['brand'],
      model: json['model'],
      serialNumber: json['serialNumber'],
      problemDescription: json['problemDescription'],
      accessories: accessoriesList,
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repairOrderId': repairOrderId,
      'productId': productId,
      'deviceType': deviceType,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'problemDescription': problemDescription,
      'accessories': accessories,
      'quantity': quantity,
      'price': price,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // Add a copyWith method to the RepairOrderItem class
  RepairOrderItem copyWith({
    String? id,
    String? repairOrderId,
    String? productId,
    String? deviceType,
    String? brand,
    String? model,
    String? serialNumber,
    String? problemDescription,
    List<String>? accessories,
    int? quantity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    Product? product,
  }) {
    return RepairOrderItem(
      id: id ?? this.id,
      repairOrderId: repairOrderId ?? this.repairOrderId,
      productId: productId ?? this.productId,
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      problemDescription: problemDescription ?? this.problemDescription,
      accessories: accessories ?? this.accessories,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }
}