import 'dart:convert';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/models/customer.dart';

enum RepairStatus {
  pending,
  diagnosed,
  inProgress,
  waitingForParts,
  completed,
  delivered,
  cancelled
}

class RepairOrder {
  final int id;
  final Customer customer;
  final String deviceType;
  final String brand;
  final String model;
  final String serialNumber;
  final String issueDescription;
  final RepairStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final User? assignedTechnician;
  final double? estimatedCost;
  final double? finalCost;
  final double? initialInspectionCost;
  final List<String>? images;
  final String? notes;
  final bool hasWarranty;
  final DateTime? warrantyExpiration;
  final List<Map<String, dynamic>>? accessories;

  var condition;

  String issue;

  RepairOrder({
    required this.issue,
    required this.id,
    required this.customer,
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.serialNumber,
    required this.issueDescription,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.assignedTechnician,
    this.estimatedCost,
    this.finalCost,
    this.initialInspectionCost,
    this.images,
    this.notes,
    this.hasWarranty = false,
    this.warrantyExpiration,
    this.accessories,
  });

  RepairOrder copyWith({
    int? id,
    Customer? customer,
    String? deviceType,
    String? brand,
    String? model,
    String? serialNumber,
    String? issueDescription,
    RepairStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    User? assignedTechnician,
    double? estimatedCost,
    double? finalCost,
    double? initialInspectionCost,
    List<String>? images,
    String? notes,
    bool? hasWarranty,
    DateTime? warrantyExpiration,
    List<Map<String, dynamic>>? accessories,
  }) {
    return RepairOrder(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      issueDescription: issueDescription ?? this.issueDescription,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      assignedTechnician: assignedTechnician ?? this.assignedTechnician,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      finalCost: finalCost ?? this.finalCost,
      initialInspectionCost: initialInspectionCost ?? this.initialInspectionCost,
      images: images ?? this.images,
      notes: notes ?? this.notes,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      warrantyExpiration: warrantyExpiration ?? this.warrantyExpiration,
      accessories: accessories ?? this.accessories, issue: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer': customer.toMap(),
      'deviceType': deviceType,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'issueDescription': issueDescription,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'assignedTechnician': assignedTechnician?.toMap(),
      'estimatedCost': estimatedCost,
      'finalCost': finalCost,
      'initialInspectionCost': initialInspectionCost,
      'images': images,
      'notes': notes,
      'hasWarranty': hasWarranty,
      'warrantyExpiration': warrantyExpiration?.millisecondsSinceEpoch,
      'accessories': accessories,
    };
  }

  factory RepairOrder.fromMap(Map<String, dynamic> map) {
    return RepairOrder(
      id: map['id']?.toInt() ?? 0,
      customer: Customer.fromMap(map['customer']),
      deviceType: map['deviceType'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      issueDescription: map['issueDescription'] ?? '',
      status: RepairStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => RepairStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      assignedTechnician: map['assignedTechnician'] != null
          ? User.fromMap(map['assignedTechnician'])
          : null,
      estimatedCost: map['estimatedCost'],
      finalCost: map['finalCost'],
      initialInspectionCost: map['initialInspectionCost'],
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      notes: map['notes'],
      hasWarranty: map['hasWarranty'] ?? false,
      warrantyExpiration: map['warrantyExpiration'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['warrantyExpiration'])
          : null,
      accessories: map['accessories'] != null ? List<Map<String, dynamic>>.from(map['accessories']) : null, issue: '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RepairOrder.fromJson(String source) =>
      RepairOrder.fromMap(json.decode(source));

  @override
  String toString() {
    return 'RepairOrder(id: $id, customer: $customer, deviceType: $deviceType, brand: $brand, model: $model, serialNumber: $serialNumber, issueDescription: $issueDescription, status: $status, createdAt: $createdAt, completedAt: $completedAt, assignedTechnician: $assignedTechnician, estimatedCost: $estimatedCost, finalCost: $finalCost, initialInspectionCost: $initialInspectionCost, images: $images, notes: $notes, hasWarranty: $hasWarranty, warrantyExpiration: $warrantyExpiration, accessories: $accessories)';
  }
}