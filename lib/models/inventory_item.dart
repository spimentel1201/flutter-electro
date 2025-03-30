import 'dart:convert';

class InventoryItem {
  final int id;
  final String name;
  final String category;
  final String status; // Available, In Use, Out of Stock, etc.
  final String location;
  final int quantity;
  final double? purchasePrice;
  final double? sellingPrice;
  final String? serialNumber;
  final String? description;
  final DateTime addedDate;
  final DateTime? lastUpdated;
  final String? supplier;
  final List<String>? images;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.location,
    required this.quantity,
    this.purchasePrice,
    this.sellingPrice,
    this.serialNumber,
    this.description,
    required this.addedDate,
    this.lastUpdated,
    this.supplier,
    this.images,
  });

  InventoryItem copyWith({
    int? id,
    String? name,
    String? category,
    String? status,
    String? location,
    int? quantity,
    double? purchasePrice,
    double? sellingPrice,
    String? serialNumber,
    String? description,
    DateTime? addedDate,
    DateTime? lastUpdated,
    String? supplier,
    List<String>? images,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      serialNumber: serialNumber ?? this.serialNumber,
      description: description ?? this.description,
      addedDate: addedDate ?? this.addedDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      supplier: supplier ?? this.supplier,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'location': location,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'serialNumber': serialNumber,
      'description': description,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'supplier': supplier,
      'images': images,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      location: map['location'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      purchasePrice: map['purchasePrice'],
      sellingPrice: map['sellingPrice'],
      serialNumber: map['serialNumber'],
      description: map['description'],
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate']),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : null,
      supplier: map['supplier'],
      images: map['images'] != null ? List<String>.from(map['images']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory InventoryItem.fromJson(String source) => InventoryItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, category: $category, status: $status, location: $location, quantity: $quantity, purchasePrice: $purchasePrice, sellingPrice: $sellingPrice, serialNumber: $serialNumber, description: $description, addedDate: $addedDate, lastUpdated: $lastUpdated, supplier: $supplier, images: $images)';
  }
}