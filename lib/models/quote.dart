import 'dart:convert';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/models/customer.dart';

class QuoteItem {
  final String id;
  final String quoteId;
  final String description;
  final double price;
  final int quantity;
  final bool isLabor;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuoteItem({
    required this.id,
    required this.quoteId,
    required this.description,
    required this.price,
    required this.quantity,
    this.isLabor = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get total => price * quantity;

  QuoteItem copyWith({
    String? id,
    String? quoteId,
    String? description,
    double? price,
    int? quantity,
    bool? isLabor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isLabor: isLabor ?? this.isLabor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteId': quoteId,
      'description': description,
      'price': price,
      'quantity': quantity,
      'isLabor': isLabor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      quoteId: json['quoteId'],
      description: json['description'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity']?.toInt() ?? 1,
      isLabor: json['isLabor'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Quote {
  final String id;
  final String repairOrderId;
  final String customerId;
  final String technicianId;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuoteItem> items;
  
  // Optional references to related objects
  final RepairOrder? repairOrder;
  final Customer? customer;
  final User? technician;

  Quote({
    required this.id,
    required this.repairOrderId,
    required this.customerId,
    required this.technicianId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.repairOrder,
    this.customer,
    this.technician,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    List<QuoteItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => QuoteItem.fromJson(item))
          .toList();
    }

    return Quote(
      id: json['id'],
      repairOrderId: json['repairOrderId'],
      customerId: json['customerId'],
      technicianId: json['technicianId'],
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: itemsList,
      repairOrder: json['repairOrder'] != null ? RepairOrder.fromJson(json['repairOrder']) : null,
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      technician: json['technician'] != null ? User.fromJson(json['technician']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repairOrderId': repairOrderId,
      'customerId': customerId,
      'technicianId': technicianId,
      'status': status,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Status enum to match Prisma schema
class QuoteStatus {
  static const String PENDING = 'PENDING';
  static const String APPROVED = 'APPROVED';
  static const String REJECTED = 'REJECTED';
  static const String EXPIRED = 'EXPIRED';
}