import 'dart:convert';
import 'package:electro_workshop/models/product.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/models/user.dart';

class SaleItem {
  final int id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double discount;

  SaleItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get subtotal => unitPrice * quantity;
  double get totalDiscount => discount * quantity;
  double get total => subtotal - totalDiscount;

  SaleItem copyWith({
    int? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? discount,
  }) {
    return SaleItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id']?.toInt() ?? 0,
      product: Product.fromMap(map['product']),
      quantity: map['quantity']?.toInt() ?? 0,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SaleItem.fromJson(String source) => SaleItem.fromMap(json.decode(source));
}

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  check,
  other
}

enum SaleStatus {
  pending,
  completed,
  cancelled,
  refunded
}

class Sale {
  final int id;
  final String invoiceNumber;
  final Customer customer;
  final User seller;
  final List<SaleItem> items;
  final DateTime saleDate;
  final SaleStatus status;
  final PaymentMethod paymentMethod;
  final double taxRate;
  final double taxAmount;
  final double subtotal;
  final double totalDiscount;
  final double total;
  final String? notes;

  Sale({
    required this.id,
    required this.invoiceNumber,
    required this.customer,
    required this.seller,
    required this.items,
    required this.saleDate,
    required this.status,
    required this.paymentMethod,
    required this.taxRate,
    required this.taxAmount,
    required this.subtotal,
    required this.totalDiscount,
    required this.total,
    this.notes,
  });

  Sale copyWith({
    int? id,
    String? invoiceNumber,
    Customer? customer,
    User? seller,
    List<SaleItem>? items,
    DateTime? saleDate,
    SaleStatus? status,
    PaymentMethod? paymentMethod,
    double? taxRate,
    double? taxAmount,
    double? subtotal,
    double? totalDiscount,
    double? total,
    String? notes,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customer: customer ?? this.customer,
      seller: seller ?? this.seller,
      items: items ?? this.items,
      saleDate: saleDate ?? this.saleDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      subtotal: subtotal ?? this.subtotal,
      totalDiscount: totalDiscount ?? this.totalDiscount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customer': customer.toMap(),
      'seller': seller.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'saleDate': saleDate.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'subtotal': subtotal,
      'totalDiscount': totalDiscount,
      'total': total,
      'notes': notes,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id']?.toInt() ?? 0,
      invoiceNumber: map['invoiceNumber'] ?? '',
      customer: Customer.fromMap(map['customer']),
      seller: User.fromMap(map['seller']),
      items: List<SaleItem>.from(map['items']?.map((x) => SaleItem.fromMap(x))),
      saleDate: DateTime.fromMillisecondsSinceEpoch(map['saleDate']),
      status: SaleStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => SaleStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      taxRate: map['taxRate']?.toDouble() ?? 0.0,
      taxAmount: map['taxAmount']?.toDouble() ?? 0.0,
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      totalDiscount: map['totalDiscount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Sale.fromJson(String source) => Sale.fromMap(json.decode(source));
}