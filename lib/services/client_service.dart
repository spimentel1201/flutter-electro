import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/config/env_config.dart';

class ClientService {
  final String baseUrl = EnvConfig.apiBaseUrl;

  Future<List<Customer>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/customers'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Customer.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }

  Future<Customer> getClient(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/customers/$id'));
    
    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load client');
    }
  }

  Future<Customer> createClient(Customer client) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(client.toJson()..remove('id')), // Remove id for creation
    );
    
    if (response.statusCode == 201) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create client');
    }
  }

  Future<Customer> updateClient(Customer client) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/${client.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(client.toJson()),
    );
    
    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update client');
    }
  }

  Future<void> deleteClient(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/customers/$id'));
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete client');
    }
  }
}