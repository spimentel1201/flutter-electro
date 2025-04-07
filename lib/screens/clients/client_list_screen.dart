import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/services/customer_service.dart';
import 'package:electro_workshop/screens/clients/client_form_screen.dart';
import 'package:electro_workshop/screens/clients/client_detail_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({Key? key}) : super(key: key);

  @override
  _ClientListScreenState createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final ClientService _clientService = ClientService();
  List<Customer> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final clients = await _clientService.getClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load clients: ${e.toString()}');
    }
  }

  List<Customer> get _filteredClients {
    if (_searchQuery.isEmpty) {
      return _clients;
    }
    
    final query = _searchQuery.toLowerCase();
    return _clients.where((client) {
      return client.name.toLowerCase().contains(query) ||
             (client.email?.toLowerCase().contains(query) ?? false) ||
             client.phone.toLowerCase().contains(query) ||
             client.documentNumber.toLowerCase().contains(query);
    }).toList();
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text('No se encontraron clientes'))
                    : _buildCustomerList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ClientFormScreen(isEditing: false),
            ),
          ).then((_) => _loadCustomers());
        },
        tooltip: 'Agregar Cliente',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.05),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar clientes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Tipo de documento:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: _documentTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocumentType = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return ListView.builder(
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(customer.name),
            subtitle: Text(
              '${customer.documentType ?? 'Doc'}: ${customer.documentNumber ?? 'N/A'} | ${customer.phone}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ClientDetailScreen(customerId: customer.id),
                ),
              ).then((_) => _loadCustomers());
            },
          ),
        );
      },
    );
  }
}