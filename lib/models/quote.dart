import 'dart:convert';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/models/user.dart';

class QuoteItem {
  final int id;
  final String description;
  final double price;
  final int quantity;
  final bool isLabor;

  QuoteItem({
    required this.id,
    required this.description,
    required this.price,
    required this.quantity,
    this.isLabor = false,
  });

  double get total => price * quantity;

  QuoteItem copyWith({
    int? id,
    String? description,
    double? price,
    int? quantity,
    bool? isLabor,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isLabor: isLabor ?? this.isLabor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'price': price,
      'quantity': quantity,
      'isLabor': isLabor,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id']?.toInt() ?? 0,
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      isLabor: map['isLabor'] ?? false,
    );
  }
}

enum QuoteStatus {
  draft,
  pending,
  approved,
  rejected,
  expired
}

class Quote {
  final int id;
  final RepairOrder repairOrder;
  final List<QuoteItem> items;
  final QuoteStatus status;
  final DateTime createdAt;
  final DateTime validUntil;
  final User createdBy;
  final String? notes;
  final double? discount;
  final double? tax;

  Quote({
    required this.id,
    required this.repairOrder,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.validUntil,
    required this.createdBy,
    this.notes,
    this.discount,
    this.tax,
  });

  // Calculate subtotal (sum of all items)
  double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  // Calculate discount amount
  double get discountAmount => discount != null ? subtotal * (discount! / 100) : 0;

  // Calculate tax amount
  double get taxAmount => tax != null ? (subtotal - discountAmount) * (tax! / 100) : 0;

  // Calculate total
  double get total => subtotal - discountAmount + taxAmount;

  Quote copyWith({
    int? id,
    RepairOrder? repairOrder,
    List<QuoteItem>? items,
    QuoteStatus? status,
    DateTime? createdAt,
    DateTime? validUntil,
    User? createdBy,
    String? notes,
    double? discount,
    double? tax,
  }) {
    return Quote(
      id: id ?? this.id,
      repairOrder: repairOrder ?? this.repairOrder,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'repairOrder': repairOrder.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'validUntil': validUntil.millisecondsSinceEpoch,
      'createdBy': createdBy.toMap(),
      'notes': notes,
      'discount': discount,
      'tax': tax,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id']?.toInt() ?? 0,
      repairOrder: RepairOrder.fromMap(map['repairOrder']),
      items: List<QuoteItem>.from(map['items']?.map((x) => QuoteItem.fromMap(x))),
      status: QuoteStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => QuoteStatus.draft,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      validUntil: DateTime.fromMillisecondsSinceEpoch(map['validUntil']),
      createdBy: User.fromMap(map['createdBy']),
      notes: map['notes'],
      discount: map['discount'],
      tax: map['tax'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Quote.fromJson(String source) => Quote.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Quote(id: $id, repairOrder: $repairOrder, items: $items, status: $status, createdAt: $createdAt, validUntil: $validUntil, createdBy: $createdBy, notes: $notes, discount: $discount, tax: $tax)';
  }
}