import 'package:electro_workshop/models/product.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/models/user.dart';

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final double price;
  final double discount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional reference to related product
  final Product? product;

  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  double get subtotal => price * quantity;
  double get totalDiscount => discount * quantity;
  double get total => subtotal - totalDiscount;

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    int? quantity,
    double? price,
    double? discount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Product? product,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      saleId: json['saleId'],
      productId: json['productId'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      discount: json['discount']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

class Sale {
  final String id;
  final String? customerId;
  final String userId;
  final String? customerName;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SaleItem> items;
  final double? taxRate;
  final double? taxAmount;
  final double? subtotal;
  final double? totalDiscount;
  final String? notes;
  
  // Optional references to related objects
  final Customer? customer;
  final User? user;

  Sale({
    required this.id,
    this.customerId,
    required this.userId,
    this.customerName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.taxRate,
    this.taxAmount,
    this.subtotal,
    this.totalDiscount,
    this.notes,
    this.customer,
    this.user,
  });

  Sale copyWith({
    String? id,
    String? customerId,
    String? userId,
    String? customerName,
    double? totalAmount,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SaleItem>? items,
    double? taxRate,
    double? taxAmount,
    double? subtotal,
    double? totalDiscount,
    String? notes,
    Customer? customer,
    User? user,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      notes: notes ?? this.notes,
      customer: customer ?? this.customer,
      user: user ?? this.user,
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    List<SaleItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => SaleItem.fromJson(item))
          .toList();
    }

    return Sale(
      id: json['id'],
      customerId: json['customerId'],
      userId: json['userId'],
      customerName: json['customerName'],
      totalAmount: json['totalAmount'].toDouble(),
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: itemsList,
      taxRate: json['taxRate']?.toDouble(),
      taxAmount: json['taxAmount']?.toDouble(),
      subtotal: json['subtotal']?.toDouble(),
      totalDiscount: json['totalDiscount']?.toDouble(),
      notes: json['notes'],
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'userId': userId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'subtotal': subtotal,
      'totalDiscount': totalDiscount,
      'notes': notes,
    };
  }
}

// PaymentMethod enum to match Prisma schema
class PaymentMethod {
  static const String CASH = 'CASH';
  static const String CREDIT_CARD = 'CREDIT_CARD';
  static const String DEBIT_CARD = 'DEBIT_CARD';
  static const String TRANSFER = 'TRANSFER';
  static const String YAPE = 'YAPE';
  static const String PLIN = 'PLIN';
}
