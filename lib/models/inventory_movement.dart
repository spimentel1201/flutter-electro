import 'dart:convert';

enum MovementType {
  entry,
  exit,
  adjustment
}

class InventoryMovement {
  final int id;
  final int inventoryItemId;
  final String itemName; // For easier reference
  final MovementType type;
  final int quantity;
  final String? reason;
  final String? performedBy;
  final DateTime timestamp;
  final double? priceAtMovement;

  InventoryMovement({
    required this.id,
    required this.inventoryItemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    this.reason,
    this.performedBy,
    required this.timestamp,
    this.priceAtMovement,
  });

  InventoryMovement copyWith({
    int? id,
    int? inventoryItemId,
    String? itemName,
    MovementType? type,
    int? quantity,
    String? reason,
    String? performedBy,
    DateTime? timestamp,
    double? priceAtMovement,
  }) {
    return InventoryMovement(
      id: id ?? this.id,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      itemName: itemName ?? this.itemName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      reason: reason ?? this.reason,
      performedBy: performedBy ?? this.performedBy,
      timestamp: timestamp ?? this.timestamp,
      priceAtMovement: priceAtMovement ?? this.priceAtMovement,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventoryItemId': inventoryItemId,
      'itemName': itemName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'reason': reason,
      'performedBy': performedBy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'priceAtMovement': priceAtMovement,
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id']?.toInt() ?? 0,
      inventoryItemId: map['inventoryItemId']?.toInt() ?? 0,
      itemName: map['itemName'] ?? '',
      type: MovementType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MovementType.adjustment,
      ),
      quantity: map['quantity']?.toInt() ?? 0,
      reason: map['reason'],
      performedBy: map['performedBy'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      priceAtMovement: map['priceAtMovement']?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory InventoryMovement.fromJson(String source) => 
      InventoryMovement.fromMap(json.decode(source));

  @override
  String toString() {
    return 'InventoryMovement(id: $id, inventoryItemId: $inventoryItemId, itemName: $itemName, type: $type, quantity: $quantity, reason: $reason, performedBy: $performedBy, timestamp: $timestamp, priceAtMovement: $priceAtMovement)';
  }
}