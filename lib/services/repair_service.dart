import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/services/api_service.dart';

class RepairService {
  final ApiService _apiService;

  RepairService({required ApiService apiService}) : _apiService = apiService;

  // Get all repair orders
  Future<List<RepairOrder>> getAllRepairOrders() async {
    try {
      final response = await _apiService.get('repairs', queryParams: {});
      return (response as List)
          .map((order) => RepairOrder.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders: ${e.toString()}');
    }
  }

  // Get repair orders by status
  Future<List<RepairOrder>> getRepairOrdersByStatus(String status) async {
    try {
      final response = await _apiService.get('repairs/status/$status', queryParams: {});
      return (response as List)
          .map((order) => RepairOrder.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders by status: ${e.toString()}');
    }
  }

  // Get repair orders by technician
  Future<List<RepairOrder>> getRepairOrdersByTechnician(String technicianId) async {
    try {
      final response = await _apiService.get('repairs/technician/$technicianId', queryParams: {});
      return (response as List)
          .map((order) => RepairOrder.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders by technician: ${e.toString()}');
    }
  }

  // Get repair orders by customer
  Future<List<RepairOrder>> getRepairOrdersByCustomer(String customerId) async {
    try {
      final response = await _apiService.get('repairs/customer/$customerId', queryParams: {});
      return (response as List)
          .map((order) => RepairOrder.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders by customer: ${e.toString()}');
    }
  }

  // Get repair order by ID
  Future<RepairOrder> getRepairOrderById(String id) async {
    try {
      final response = await _apiService.get('repairs/$id', queryParams: {});
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load repair order: ${e.toString()}');
    }
  }

  // Create new repair order
  Future<RepairOrder> createRepairOrder(RepairOrder order) async {
    try {
      final response = await _apiService.post('repairs', data: order.toJson());
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create repair order: ${e.toString()}');
    }
  }

  // Update repair order
  Future<RepairOrder> updateRepairOrder(RepairOrder order, String s) async {
    try {
      final response = await _apiService.put('repairs/${order.id}', data: order.toJson());
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update repair order: ${e.toString()}');
    }
  }

  // Update repair order status
  Future<RepairOrder> updateRepairOrderStatus(String id, String status) async {
    try {
      final response = await _apiService.put('repairs/$id/status', data: {
        'status': status,
      });
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update repair order status: ${e.toString()}');
    }
  }

  // Assign technician to repair order
  Future<RepairOrder> assignTechnician(String repairId, String technicianId) async {
    try {
      final response = await _apiService.put('repairs/$repairId/assign', data: {
        'technician_id': technicianId,
      });
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign technician: ${e.toString()}');
    }
  }

  // Add repair notes
  Future<RepairOrder> addRepairNotes(String repairId, String notes) async {
    try {
      final response = await _apiService.put('repairs/$repairId/notes', data: {
        'notes': notes,
      });
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add repair notes: ${e.toString()}');
    }
  }

  // Complete repair order
  Future<RepairOrder> completeRepairOrder(String repairId, double finalCost) async {
    try {
      final response = await _apiService.put('repairs/$repairId/complete', data: {
        'final_cost': finalCost,
      });
      return RepairOrder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete repair order: ${e.toString()}');
    }
  }

  // Delete repair order
  Future<void> deleteRepairOrder(String id) async {
    try {
      await _apiService.delete('repairs/$id');
    } catch (e) {
      throw Exception('Failed to delete repair order: ${e.toString()}');
    }
  }
}