import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/config/env_config.dart';

class QuoteService {
  final String baseUrl = EnvConfig.apiBaseUrl;

  Future<List<Quote>> getAllQuotes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'] ?? [];
      return data.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotes: ${response.statusCode}');
    }
  }

  Future<Quote> getQuoteById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Quote.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to load quote: ${response.statusCode}');
    }
  }

  Future<Quote> createQuote(Quote quote) async {
    final Map<String, dynamic> requestData = {
      'repairOrderId': quote.repairOrderId,
      'customerId': quote.customerId,
      'technicianId': quote.technicianId,
      'status': quote.status,
      'items': quote.items.map((item) => {
        'description': item.description,
        'price': item.price,
        'quantity': item.quantity,
        'isLabor': item.isLabor,
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/quotes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Quote.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to create quote: ${response.statusCode}');
    }
  }

  Future<Quote> updateQuote(Quote quote) async {
    final Map<String, dynamic> requestData = {
      'status': quote.status,
      'items': quote.items.map((item) => {
        'id': item.id.isNotEmpty ? item.id : null,
        'description': item.description,
        'price': item.price,
        'quantity': item.quantity,
        'isLabor': item.isLabor,
      }).toList(),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/quotes/${quote.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestData),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return Quote.fromJson(responseData['data']);
    } else {
      throw Exception('Failed to update quote: ${response.statusCode}');
    }
  }

  Future<void> updateQuoteStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/quotes/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update quote status: ${response.statusCode}');
    }
  }

  Future<void> convertToSale(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quotes/$id/convert'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to convert quote to sale: ${response.statusCode}');
    }
  }

  Future<void> deleteQuote(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/quotes/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete quote: ${response.statusCode}');
    }
  }
  
  Future<List<Quote>> getQuotesByRepairOrder(String repairOrderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quotes/repair-order/$repairOrderId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'] ?? [];
      return data.map((json) => Quote.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load quotes for repair order: ${response.statusCode}');
    }
  }

  sendQuoteToCustomer(String id, String? email) {}
}