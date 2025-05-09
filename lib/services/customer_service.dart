import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/services/api_service.dart';

class CustomerService {
  final ApiService _apiService;

  CustomerService({required ApiService apiService}) : _apiService = apiService;

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    try {
      final response = await _apiService.get('customers');
      return (response as List)
          .map((customer) => Customer.fromMap(customer))
          .toList();
    } catch (e) {
      throw Exception('Failed to load customers: ${e.toString()}');
    }
  }

  // Get customer by ID
  Future<Customer> getCustomerById(int id) async {
    try {
      final response = await _apiService.get('customers/$id');
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to load customer: ${e.toString()}');
    }
  }

  // Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final response = await _apiService.get('customers/search?q=$query');
      return (response as List)
          .map((customer) => Customer.fromMap(customer))
          .toList();
    } catch (e) {
      throw Exception('Failed to search customers: ${e.toString()}');
    }
  }

  // Create new customer
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _apiService.post('customers', data: customer.toMap());
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create customer: ${e.toString()}');
    }
  }

  // Update customer
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final response = await _apiService.put('customers/${customer.id}', data: customer.toMap());
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update customer: ${e.toString()}');
    }
  }

  // Delete customer
  Future<void> deleteCustomer(int id) async {
    try {
      await _apiService.delete('customers/$id');
    } catch (e) {
      throw Exception('Failed to delete customer: ${e.toString()}');
    }
  }

  // Get customer repair history
  Future<List<Map<String, dynamic>>> getCustomerRepairHistory(int customerId) async {
    try {
      final response = await _apiService.get('customers/$customerId/repairs');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load customer repair history: ${e.toString()}');
    }
  }

  // Add customer notes
  Future<Customer> addCustomerNotes(int customerId, String notes) async {
    try {
      final response = await _apiService.put('customers/$customerId/notes', data: {
        'notes': notes,
      });
      return Customer.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add customer notes: ${e.toString()}');
    }
  }
}