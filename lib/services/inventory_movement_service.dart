import 'package:electro_workshop/models/inventory_movement.dart';
import 'package:electro_workshop/services/api_service.dart';
import 'package:electro_workshop/services/inventory_service.dart';
import 'package:electro_workshop/models/inventory_item.dart';

class InventoryMovementService {
  final ApiService _apiService;
  final InventoryService _inventoryService;

  InventoryMovementService({
    required ApiService apiService,
    required InventoryService inventoryService,
  }) : 
    _apiService = apiService,
    _inventoryService = inventoryService;

  // Get all movements
  Future<List<InventoryMovement>> getAllMovements() async {
    try {
      final response = await _apiService.get('inventory/movements', queryParams: {});
      return (response as List)
          .map((item) => InventoryMovement.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory movements: ${e.toString()}');
    }
  }

  // Get movements by item ID
  Future<List<InventoryMovement>> getMovementsByItemId(int itemId) async {
    try {
      final response = await _apiService.get('inventory/movements/item/$itemId', queryParams: {});
      return (response as List)
          .map((item) => InventoryMovement.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load movements for item: ${e.toString()}');
    }
  }

  // Create a new movement and update inventory item quantity
  Future<InventoryMovement> createMovement(InventoryMovement movement) async {
    try {
      // First, get the current inventory item
      final item = await _inventoryService.getItemById(movement.inventoryItemId);
      
      // Calculate new quantity based on movement type
      int newQuantity = item.quantity;
      
      switch (movement.type) {
        case MovementType.entry:
          newQuantity += movement.quantity;
          break;
        case MovementType.exit:
          newQuantity -= movement.quantity;
          if (newQuantity < 0) {
            throw Exception('Cannot remove more items than available in inventory');
          }
          break;
        case MovementType.adjustment:
          newQuantity = movement.quantity; // Direct set for adjustments
          break;
      }
      
      // Update the inventory item quantity
      await _inventoryService.updateItemQuantity(item.id, newQuantity);
      
      // Create the movement record
      final response = await _apiService.post('inventory/movements', data: movement.toMap());
      return InventoryMovement.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create inventory movement: ${e.toString()}');
    }
  }

  // Get movements by date range
  Future<List<InventoryMovement>> getMovementsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiService.get(
          'inventory/movements/date-range?start=${startDate.millisecondsSinceEpoch}&end=${endDate.millisecondsSinceEpoch}', queryParams: {});
      return (response as List)
          .map((item) => InventoryMovement.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load movements by date range: ${e.toString()}');
    }
  }

  // Get movements by type
  Future<List<InventoryMovement>> getMovementsByType(MovementType type) async {
    try {
      final response = await _apiService.get(
          'inventory/movements/type/${type.toString().split('.').last}', queryParams: {});
      return (response as List)
          .map((item) => InventoryMovement.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Failed to load movements by type: ${e.toString()}');
    }
  }
}