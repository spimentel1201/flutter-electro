class QuoteItem {
  final String id;
  final String quoteId;
  final int quantity;
  final double price;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuoteItem({
    required this.id,
    required this.quoteId,
    required this.quantity,
    required this.price,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      id: json['id'],
      quoteId: json['quoteId'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quoteId': quoteId,
      'quantity': quantity,
      'price': price,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}