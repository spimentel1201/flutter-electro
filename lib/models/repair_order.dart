import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/models/repair_order_item.dart';

class RepairOrder {
  final String id;
  final String customerId;
  final String technicianId;
  final String status;
  final String description;
  final String? notes;
  final double initialReviewCost;
  final double totalCost;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RepairOrderItem> items;
  
  // Optional references to related objects
  final Customer? customer;
  final User? technician;

  RepairOrder({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.status,
    required this.description,
    this.notes,
    this.initialReviewCost = 0.0,
    this.totalCost = 0.0,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.customer,
    this.technician,
  });

  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    List<RepairOrderItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => RepairOrderItem.fromJson(item))
          .toList();
    }

    return RepairOrder(
      id: json['id'],
      customerId: json['customerId'],
      technicianId: json['technicianId'],
      status: json['status'],
      description: json['description'],
      notes: json['notes'],
      initialReviewCost: json['initialReviewCost']?.toDouble() ?? 0.0,
      totalCost: json['totalCost']?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: itemsList,
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      technician: json['technician'] != null ? User.fromJson(json['technician']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'technicianId': technicianId,
      'status': status,
      'description': description,
      'notes': notes,
      'initialReviewCost': initialReviewCost,
      'totalCost': totalCost,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Status enum to match Prisma schema
class RepairOrderStatus {
  static const String RECEIVED = 'RECEIVED';
  static const String DIAGNOSED = 'DIAGNOSED';
  static const String IN_PROGRESS = 'IN_PROGRESS';
  static const String WAITING_FOR_PARTS = 'WAITING_FOR_PARTS';
  static const String COMPLETED = 'COMPLETED';
  static const String DELIVERED = 'DELIVERED';
  static const String CANCELLED = 'CANCELLED';
}