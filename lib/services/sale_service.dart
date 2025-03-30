import 'package:electro_workshop/models/sale.dart';
import 'package:electro_workshop/models/product.dart';
import 'package:electro_workshop/services/api_service.dart';
import 'package:electro_workshop/services/product_service.dart';

class SaleService {
  final ApiService _apiService;
  final ProductService _productService;

  SaleService({
    required ApiService apiService,
    required ProductService productService,
  }) : 
    _apiService = apiService,
    _productService = productService;

  // Get all sales
  Future<List<Sale>> getAllSales() async {
    try {
      final response = await _apiService.get('sales');
      return (response as List)
          .map((item) => Sale.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales: ${e.toString()}');
    }
  }

  // Get sales by date range
  Future<List<Sale>> getSalesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        'sales/date-range?start=${startDate.millisecondsSinceEpoch}&end=${endDate.millisecondsSinceEpoch}'
      );
      return (response as List)
          .map((item) => Sale.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales by date range: ${e.toString()}');
    }
  }

  // Get sales by customer
  Future<List<Sale>> getSalesByCustomer(int customerId) async {
    try {
      final response = await _apiService.get('sales/customer/$customerId');
      return (response as List)
          .map((item) => Sale.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sales by customer: ${e.toString()}');
    }
  }

  // Get sale by ID
  Future<Sale> getSaleById(int id) async {
    try {
      final response = await _apiService.get('sales/$id');
      return Sale.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load sale: ${e.toString()}');
    }
  }

  // Create new sale
  Future<Sale> createSale(Sale sale) async {
    try {
      // Update product stock quantities
      for (var item in sale.items) {
        await _productService.updateProductStock(
          item.product.id, 
          item.product.stock - item.quantity
        );
      }
      
      final response = await _apiService.post('sales', data: sale.toMap());
      return Sale.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create sale: ${e.toString()}');
    }
  }

  // Update sale
  Future<Sale> updateSale(Sale sale) async {
    try {
      final response = await _apiService.put('sales/${sale.id}', data: sale.toMap());
      return Sale.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update sale: ${e.toString()}');
    }
  }

  // Cancel sale
  Future<Sale> cancelSale(int id) async {
    try {
      // Get the sale first
      final sale = await getSaleById(id);
      
      // Restore product stock quantities
      for (var item in sale.items) {
        await _productService.updateProductStock(
          item.product.id, 
          item.product.stock + item.quantity
        );
      }
      
      final response = await _apiService.put('sales/$id/cancel');
      return Sale.fromMap(response);
    } catch (e) {
      throw Exception('Failed to cancel sale: ${e.toString()}');
    }
  }

  // Get sales statistics
  Future<Map<String, dynamic>> getSalesStatistics(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
        'sales/statistics?start=${startDate.millisecondsSinceEpoch}&end=${endDate.millisecondsSinceEpoch}'
      );
      return response;
    } catch (e) {
      throw Exception('Failed to load sales statistics: ${e.toString()}');
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts(DateTime startDate, DateTime endDate, {int limit = 10}) async {
    try {
      final response = await _apiService.get(
        'sales/top-products?start=${startDate.millisecondsSinceEpoch}&end=${endDate.millisecondsSinceEpoch}&limit=$limit'
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load top selling products: ${e.toString()}');
    }
  }

  // Generate invoice
  Future<String> generateInvoice(int saleId) async {
    try {
      final response = await _apiService.get('sales/$saleId/invoice');
      return response['invoiceUrl'];
    } catch (e) {
      throw Exception('Failed to generate invoice: ${e.toString()}');
    }
  }
}