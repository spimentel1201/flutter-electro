import 'package:electro_workshop/models/product.dart';
import 'package:electro_workshop/services/api_service.dart';

class ProductService {
  final ApiService _apiService;

  ProductService({required ApiService apiService}) : _apiService = apiService;

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _apiService.get('products');
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _apiService.get('products/category/$category');
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products by category: ${e.toString()}');
    }
  }

  // Get product by ID
  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiService.get('products/$id');
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load product: ${e.toString()}');
    }
  }

  // Create new product
  Future<Product> createProduct(Product product) async {
    try {
      final response = await _apiService.post('products', data: product.toJson());
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }

  // Update product
  Future<Product> updateProduct(Product product) async {
    try {
      final response = await _apiService.put('products/${product.id}', data: product.toJson());
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await _apiService.delete('products/$id');
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // Update product stock
  Future<Product> updateProductStock(String id, int stock) async {
    try {
      final response = await _apiService.put('products/$id/stock', data: {
        'stock': stock,
      });
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update product stock: ${e.toString()}');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _apiService.get('products/search?q=$query');
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }

  // Get active products
  Future<List<Product>> getActiveProducts() async {
    try {
      final response = await _apiService.get('products/active');
      return (response as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load active products: ${e.toString()}');
    }
  }
}