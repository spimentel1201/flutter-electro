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
          .map((quote) => Quote.fromMap(quote))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quotes: ${e.toString()}');
    }
  }

  // Get quotes by repair order
  Future<List<Quote>> getQuotesByRepairOrder(int repairOrderId) async {
    try {
      final response = await _apiService.get('quotes/repair/$repairOrderId');
      return (response as List)
          .map((quote) => Quote.fromMap(quote))
          .toList();
    } catch (e) {
      throw Exception('Failed to load quotes by repair order: ${e.toString()}');
    }
  }

  // Get quote by ID
  Future<Quote> getQuoteById(int id) async {
    try {
      final response = await _apiService.get('quotes/$id');
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load quote: ${e.toString()}');
    }
  }

  // Create new quote
  Future<Quote> createQuote(Quote quote) async {
    try {
      final response = await _apiService.post('quotes', data: quote.toMap());
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create quote: ${e.toString()}');
    }
  }

  // Update quote
  Future<Quote> updateQuote(Quote quote) async {
    try {
      final response = await _apiService.put('quotes/${quote.id}', data: quote.toMap());
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update quote: ${e.toString()}');
    }
  }

  // Update quote status
  Future<Quote> updateQuoteStatus(int id, QuoteStatus status) async {
    try {
      final statusStr = status.toString().split('.').last;
      final response = await _apiService.put('quotes/$id/status', data: {
        'status': statusStr,
      });
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update quote status: ${e.toString()}');
    }
  }

  // Add quote item
  Future<Quote> addQuoteItem(int quoteId, QuoteItem item) async {
    try {
      final response = await _apiService.post('quotes/$quoteId/items', data: item.toMap());
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add quote item: ${e.toString()}');
    }
  }

  // Update quote item
  Future<Quote> updateQuoteItem(int quoteId, QuoteItem item) async {
    try {
      final response = await _apiService.put('quotes/$quoteId/items/${item.id}', data: item.toMap());
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update quote item: ${e.toString()}');
    }
  }

  // Remove quote item
  Future<Quote> removeQuoteItem(int quoteId, int itemId) async {
    try {
      final response = await _apiService.delete('quotes/$quoteId/items/$itemId');
      return Quote.fromMap(response);
    } catch (e) {
      throw Exception('Failed to remove quote item: ${e.toString()}');
    }
  }

  // Delete quote
  Future<void> deleteQuote(int id) async {
    try {
      await _apiService.delete('quotes/$id');
    } catch (e) {
      throw Exception('Failed to delete quote: ${e.toString()}');
    }
  }

  // Send quote to customer via email
  Future<void> sendQuoteToCustomer(int quoteId, String customerEmail) async {
    try {
      await _apiService.post('quotes/$quoteId/send', data: {
        'email': customerEmail,
      });
    } catch (e) {
      throw Exception('Failed to send quote to customer: ${e.toString()}');
    }
  }

  // Convert quote to invoice/sale
  Future<Map<String, dynamic>> convertQuoteToInvoice(int quoteId) async {
    try {
      final response = await _apiService.post('quotes/$quoteId/convert');
      return response;
    } catch (e) {
      throw Exception('Failed to convert quote to invoice: ${e.toString()}');
    }
  }
}