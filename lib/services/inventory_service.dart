import 'package:electro_workshop/models/inventory_item.dart';
import 'package:electro_workshop/services/api_service.dart';

class InventoryService {
  final ApiService _apiService;

  InventoryService({required ApiService apiService}) : _apiService = apiService;

  // Get all inventory items
  Future<List<InventoryItem>> getAllItems() async {
    try {
      final response = await _apiService.get('inventory', queryParams: {});
      return (response as List)
          .map((item) => InventoryItem.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory items: ${e.toString()}');
    }
  }

  // Get inventory items by category
  Future<List<InventoryItem>> getItemsByCategory(String category) async {
    try {
      final response = await _apiService.get('inventory/category/$category', queryParams: {});
      return (response as List)
          .map((item) => InventoryItem.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory items by category: ${e.toString()}');
    }
  }

  // Get inventory item by ID
  Future<InventoryItem> getItemById(int id) async {
    try {
      final response = await _apiService.get('inventory/$id', queryParams: {});
      return InventoryItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load inventory item: ${e.toString()}');
    }
  }

  // Create new inventory item
  Future<InventoryItem> createItem(InventoryItem item) async {
    try {
      final response = await _apiService.post('inventory', data: item.toMap());
      return InventoryItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create inventory item: ${e.toString()}');
    }
  }

  // Update inventory item
  Future<InventoryItem> updateItem(InventoryItem item) async {
    try {
      final response = await _apiService.put('inventory/${item.id}', data: item.toMap());
      return InventoryItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update inventory item: ${e.toString()}');
    }
  }

  // Delete inventory item
  Future<void> deleteItem(int id) async {
    try {
      await _apiService.delete('inventory/$id');
    } catch (e) {
      throw Exception('Failed to delete inventory item: ${e.toString()}');
    }
  }

  // Update item quantity
  Future<InventoryItem> updateItemQuantity(int id, int quantity) async {
    try {
      final response = await _apiService.put('inventory/$id/quantity', data: {
        'quantity': quantity,
      });
      return InventoryItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update item quantity: ${e.toString()}');
    }
  }

  // Search inventory items
  Future<List<InventoryItem>> searchItems(String query) async {
    try {
      final response = await _apiService.get('inventory/search?q=$query', queryParams: {});
      return (response as List)
          .map((item) => InventoryItem.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inventory items: ${e.toString()}');
    }
  }
}