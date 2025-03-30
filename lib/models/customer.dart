import 'dart:convert';

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? documentType;
  final String? documentNumber;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.documentType,
    this.documentNumber,
    this.address,
    this.notes,
    required this.createdAt,
    this.isActive = true,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? documentType,
    String? documentNumber,
    String? address,
    String? notes,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      documentType: map['documentType'],
      documentNumber: map['documentNumber'],
      address: map['address'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, phone: $phone, documentType: $documentType, documentNumber: $documentNumber, address: $address, notes: $notes, createdAt: $createdAt, isActive: $isActive)';
  }
}