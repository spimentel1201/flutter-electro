import 'package:flutter/material.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/services/client_service.dart';
import 'package:electro_workshop/screens/clients/client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final Customer client;

  const ClientDetailScreen({Key? key, required this.client}) : super(key: key);

  @override
  _ClientDetailScreenState createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  final ClientService _clientService = ClientService();
  late Customer _client;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _refreshClientDetails();
  }
  
  Future<void> _refreshClientDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedClient = await _clientService.getClient(_client.id);
      setState(() {
        _client = updatedClient;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load client details: ${e.toString()}');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditClient(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshClientDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24.0),
                    _buildRepairOrdersSection(),
                    const SizedBox(height: 24.0),
                    _buildQuotesSection(),
                    const SizedBox(height: 24.0),
                    _buildSalesSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActionsMenu(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Name', _client.name),
            if (_client.email != null) _buildInfoRow('Email', _client.email!),
            _buildInfoRow('Phone', _client.phone),
            _buildInfoRow('Document', '${_client.documentType} ${_client.documentNumber}'),
            if (_client.address != null) _buildInfoRow('Address', _client.address!),
            _buildInfoRow('Client since', _formatDate(_client.createdAt)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRepairOrdersSection() {
    // Implement this method to show repair orders
    return const Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Orders',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            Center(
              child: Text('No repair orders yet'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuotesSection() {
    // Implement this method to show quotes
    return const Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quotes',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            Center(
              child: Text('No quotes yet'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSalesSection() {
    // Implement this method to show sales
    return const Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            Center(
              child: Text('No sales yet'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _navigateToEditClient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormScreen(client: _client),
      ),
    );
    
    if (result == true) {
      _refreshClientDetails();
    }
  }
  
  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('New Repair Order'),
            onTap: () {
              Navigator.pop(context);
              _navigateToNewRepairOrder();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('New Quote'),
            onTap: () {
              Navigator.pop(context);
              _navigateToNewQuote();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('New Sale'),
            onTap: () {
              Navigator.pop(context);
              _navigateToNewSale();
            },
          ),
        ],
      ),
    );
  }
  
  void _navigateToNewRepairOrder() {
    // Implement navigation to new repair order screen
  }
  
  void _navigateToNewQuote() {
    // Implement navigation to new quote screen
  }
  
  void _navigateToNewSale() {
    // Implement navigation to new sale screen
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}