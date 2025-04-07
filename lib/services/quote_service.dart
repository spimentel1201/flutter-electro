import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/api_service.dart';

class QuoteService {
  final ApiService _apiService;

  QuoteService({required ApiService apiService}) : _apiService = apiService;

  // Get all quotes
  Future<List<Quote>> getAllQuotes() async {
    try {
      final response = await _apiService.get('quotes');
      return (response as List)
          .map((quote) => Quote.fromJson(quote))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quotes: ${e.toString()}');
    }
  }

  // Get quotes by repair order
  Future<List<Quote>> getQuotesByRepairOrder(String repairOrderId) async {
    try {
      final response = await _apiService.get('quotes/repair/$repairOrderId');
      return (response as List)
          .map((quote) => Quote.fromJson(quote))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quotes by repair order: ${e.toString()}');
    }
  }

  // Get quote by ID
  Future<Quote> getQuoteById(String id) async {
    try {
      final response = await _apiService.get('quotes/$id');
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load quote: ${e.toString()}');
    }
  }

  // Create new quote
  Future<Quote> createQuote(Quote quote) async {
    try {
      final response = await _apiService.post('quotes', data: quote.toJson());
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create quote: ${e.toString()}');
    }
  }

  // Update quote
  Future<Quote> updateQuote(Quote quote) async {
    try {
      final response = await _apiService.put('quotes/${quote.id}', data: quote.toJson());
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update quote: ${e.toString()}');
    }
  }

  // Update quote status
  Future<Quote> updateQuoteStatus(String id, QuoteStatus status) async {
    try {
      final statusStr = status.toString().split('.').last;
      final response = await _apiService.put('quotes/$id/status', data: {
        'status': statusStr,
      });
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update quote status: ${e.toString()}');
    }
  }

  // Add quote item
  Future<Quote> addQuoteItem(String quoteId, QuoteItem item) async {
    try {
      final response = await _apiService.post('quotes/$quoteId/items', data: item.toJson());
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add quote item: ${e.toString()}');
    }
  }

  // Update quote item
  Future<Quote> updateQuoteItem(String quoteId, QuoteItem item) async {
    try {
      final response = await _apiService.put('quotes/$quoteId/items/${item.id}', data: item.toJson());
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update quote item: ${e.toString()}');
    }
  }

  // Remove quote item
  Future<Quote> removeQuoteItem(String quoteId, String itemId) async {
    try {
      final response = await _apiService.delete('quotes/$quoteId/items/$itemId');
      return Quote.fromJson(response);
    } catch (e) {
      throw Exception('Failed to remove quote item: ${e.toString()}');
    }
  }

  // Delete quote
  Future<void> deleteQuote(String id) async {
    try {
      await _apiService.delete('quotes/$id');
    } catch (e) {
      throw Exception('Failed to delete quote: ${e.toString()}');
    }
  }

  // Send quote to customer via email
  Future<void> sendQuoteToCustomer(String quoteId, String customerEmail) async {
    try {
      await _apiService.post('quotes/$quoteId/send', data: {
        'email': customerEmail,
      });
    } catch (e) {
      throw Exception('Failed to send quote to customer: ${e.toString()}');
    }
  }

  // Convert quote to invoice/sale
  Future<Map<String, dynamic>> convertQuoteToInvoice(String quoteId) async {
    try {
      final response = await _apiService.post('quotes/$quoteId/convert');
      return response;
    } catch (e) {
      throw Exception('Failed to convert quote to invoice: ${e.toString()}');
    }
  }
}