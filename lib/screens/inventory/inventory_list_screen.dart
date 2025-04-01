import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/inventory_item.dart';
import 'package:electro_workshop/services/inventory_service.dart';
import 'package:electro_workshop/screens/inventory/inventory_detail_screen.dart';
import 'package:electro_workshop/screens/inventory/inventory_form_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({Key? key}) : super(key: key);

  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryService _inventoryService = GetIt.instance<InventoryService>();
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _inventoryService.getAllItems();
      final categories = items
          .map((item) => item.category)
          .toSet()
          .toList();

      setState(() {
        _inventoryItems = items;
        _filteredItems = items;
        _categories = ['All', ...categories];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load inventory items');
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _inventoryItems.where((item) {
        // Apply category filter
        final categoryMatch = _selectedCategory == 'All' || 
                            item.category == _selectedCategory;
        
        // Apply search filter
        final searchMatch = _searchQuery.isEmpty ||
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.description!.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false ||
            item.serialNumber!.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        
        return categoryMatch && searchMatch;
      }).toList();
    });
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
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventoryItems,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(child: Text('No inventory items found'))
                    : _buildInventoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InventoryFormScreen(),
            ),
          );
          if (result == true) {
            _loadInventoryItems();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Item',
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search inventory...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterItems();
            },
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _filterItems();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text('${item.category} • ${item.location}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    item.status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryDetailScreen(itemId: item.id),
                ),
              );
              if (result == true) {
                _loadInventoryItems();
              }
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'in use':
        return Colors.blue;
      case 'out of stock':
        return Colors.red;
      case 'low stock':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}