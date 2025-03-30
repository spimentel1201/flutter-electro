import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/services/api_service.dart';

class RepairService {
  final ApiService _apiService;

  RepairService({required ApiService apiService}) : _apiService = apiService;

  // Get all repair orders
  Future<List<RepairOrder>> getAllRepairOrders() async {
    try {
      final response = await _apiService.get('repairs');
      return (response as List)
          .map((order) => RepairOrder.fromMap(order))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders: ${e.toString()}');
    }
  }

  // Get repair orders by status
  Future<List<RepairOrder>> getRepairOrdersByStatus(RepairStatus status) async {
    try {
      final statusStr = status.toString().split('.').last;
      final response = await _apiService.get('repairs/status/$statusStr');
      return (response as List)
          .map((order) => RepairOrder.fromMap(order))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders by status: ${e.toString()}');
    }
  }

  // Get repair orders by technician
  Future<List<RepairOrder>> getRepairOrdersByTechnician(int technicianId) async {
    try {
      final response = await _apiService.get('repairs/technician/$technicianId');
      return (response as List)
          .map((order) => RepairOrder.fromMap(order))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders by technician: ${e.toString()}');
    }
  }

  // Get repair orders by customer
  Future<List<RepairOrder>> getRepairOrdersByCustomer(int customerId) async {
    try {
      final response = await _apiService.get('repairs/customer/$customerId');
      return (response as List)
          .map((order) => RepairOrder.fromMap(order))
          .toList();
    } catch (e) {
      throw Exception('Failed to load repair orders by customer: ${e.toString()}');
    }
  }

  // Get repair order by ID
  Future<RepairOrder> getRepairOrderById(int id) async {
    try {
      final response = await _apiService.get('repairs/$id');
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load repair order: ${e.toString()}');
    }
  }

  // Create new repair order
  Future<RepairOrder> createRepairOrder(RepairOrder order) async {
    try {
      final response = await _apiService.post('repairs', data: order.toMap());
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create repair order: ${e.toString()}');
    }
  }

  // Update repair order
  Future<RepairOrder> updateRepairOrder(RepairOrder order) async {
    try {
      final response = await _apiService.put('repairs/${order.id}', data: order.toMap());
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update repair order: ${e.toString()}');
    }
  }

  // Update repair order status
  Future<RepairOrder> updateRepairOrderStatus(int id, RepairStatus status) async {
    try {
      final statusStr = status.toString().split('.').last;
      final response = await _apiService.put('repairs/$id/status', data: {
        'status': statusStr,
      });
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update repair order status: ${e.toString()}');
    }
  }

  // Assign technician to repair order
  Future<RepairOrder> assignTechnician(int repairId, int technicianId) async {
    try {
      final response = await _apiService.put('repairs/$repairId/assign', data: {
        'technician_id': technicianId,
      });
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to assign technician: ${e.toString()}');
    }
  }

  // Add repair notes
  Future<RepairOrder> addRepairNotes(int repairId, String notes) async {
    try {
      final response = await _apiService.put('repairs/$repairId/notes', data: {
        'notes': notes,
      });
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add repair notes: ${e.toString()}');
    }
  }

  // Complete repair order
  Future<RepairOrder> completeRepairOrder(int repairId, double finalCost) async {
    try {
      final response = await _apiService.put('repairs/$repairId/complete', data: {
        'final_cost': finalCost,
      });
      return RepairOrder.fromMap(response);
    } catch (e) {
      throw Exception('Failed to complete repair order: ${e.toString()}');
    }
  }

  // Delete repair order
  Future<void> deleteRepairOrder(int id) async {
    try {
      await _apiService.delete('repairs/$id');
    } catch (e) {
      throw Exception('Failed to delete repair order: ${e.toString()}');
    }
  }
}