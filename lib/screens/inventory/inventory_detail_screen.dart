import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/inventory_item.dart';
import 'package:electro_workshop/models/inventory_movement.dart';
import 'package:electro_workshop/services/inventory_service.dart';
import 'package:electro_workshop/services/inventory_movement_service.dart';
import 'package:electro_workshop/screens/inventory/inventory_form_screen.dart';
import 'package:electro_workshop/screens/inventory/inventory_movement_form_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final int itemId;

  const InventoryDetailScreen({super.key, required this.itemId});

  @override
  _InventoryDetailScreenState createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> with SingleTickerProviderStateMixin {
  final InventoryService _inventoryService = GetIt.instance<InventoryService>();
  final InventoryMovementService _movementService = GetIt.instance<InventoryMovementService>();
  
  late TabController _tabController;
  InventoryItem? _item;
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;
  bool _isLoadingMovements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItemDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItemDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final item = await _inventoryService.getItemById(widget.itemId);
      setState(() {
        _item = item;
        _isLoading = false;
      });
      _loadMovementHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load item details');
    }
  }

  Future<void> _loadMovementHistory() async {
    setState(() {
      _isLoadingMovements = true;
    });

    try {
      final movements = await _movementService.getMovementsByItemId(widget.itemId);
      setState(() {
        _movements = movements;
        _isLoadingMovements = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMovements = false;
      });
      _showErrorSnackBar('Failed to load movement history');
    }
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
        title: Text(_isLoading ? 'Item Details' : _item!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.info_outline)),
            Tab(text: 'Movement History', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryFormScreen(item: _item),
                      ),
                    );
                    if (result == true) {
                      _loadItemDetails();
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildMovementHistoryTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryMovementFormScreen(itemId: widget.itemId, itemName: _item!.name),
            ),
          );
          if (result == true) {
            _loadItemDetails();
            _loadMovementHistory();
          }
        },
        tooltip: 'Add Movement',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDetailsTab() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _item!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_item!.status),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          _item!.status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Category', _item!.category),
                  _buildInfoRow('Location', _item!.location),
                  _buildInfoRow('Quantity', _item!.quantity.toString()),
                  if (_item!.serialNumber != null)
                    _buildInfoRow('Serial Number', _item!.serialNumber!),
                  if (_item!.purchasePrice != null)
                    _buildInfoRow('Purchase Price', '\$${_item!.purchasePrice!.toStringAsFixed(2)}'),
                  if (_item!.sellingPrice != null)
                    _buildInfoRow('Selling Price', '\$${_item!.sellingPrice!.toStringAsFixed(2)}'),
                  if (_item!.supplier != null) _buildInfoRow('Supplier', _item!.supplier!),
                  _buildInfoRow('Added Date', dateFormat.format(_item!.addedDate)),
                  if (_item!.lastUpdated != null)
                    _buildInfoRow('Last Updated', dateFormat.format(_item!.lastUpdated!)),
                ],
              ),
            ),
          ),
          if (_item!.description != null) ...[  
            const SizedBox(height: 16.0),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    Text(_item!.description!),
                  ],
                ),
              ),
            ),
          ],
          if (_item!.images != null && _item!.images!.isNotEmpty) ...[  
            const SizedBox(height: 16.0),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _item!.images!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                _item!.images![index],
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
            width: 120,
            child: Text(
              label,
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

  Widget _buildMovementHistoryTab() {
    return _isLoadingMovements
        ? const Center(child: CircularProgressIndicator())
        : _movements.isEmpty
            ? const Center(child: Text('No movement history found'))
            : ListView.builder(
                itemCount: _movements.length,
                itemBuilder: (context, index) {
                  final movement = _movements[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: ListTile(
                      leading: _getMovementIcon(movement.type),
                      title: Text(_getMovementTitle(movement)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(movement.timestamp),
                          ),
                          if (movement.reason != null && movement.reason!.isNotEmpty)
                            Text('Reason: ${movement.reason}'),
                        ],
                      ),
                      trailing: Text(
                        _getMovementQuantityText(movement),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getMovementColor(movement.type),
                        ),
                      ),
                    ),
                  );
                },
              );
  }

  Widget _getMovementIcon(MovementType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case MovementType.entry:
        iconData = Icons.add_circle;
        color = Colors.green;
        break;
      case MovementType.exit:
        iconData = Icons.remove_circle;
        color = Colors.red;
        break;
      case MovementType.adjustment:
        iconData = Icons.sync;
        color = Colors.blue;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }

  String _getMovementTitle(InventoryMovement movement) {
    switch (movement.type) {
      case MovementType.entry:
        return 'Entry';
      case MovementType.exit:
        return 'Exit';
      case MovementType.adjustment:
        return 'Adjustment';
    }
  }

  String _getMovementQuantityText(InventoryMovement movement) {
    switch (movement.type) {
      case MovementType.entry:
        return '+${movement.quantity}';
      case MovementType.exit:
        return '-${movement.quantity}';
      case MovementType.adjustment:
        return '=${movement.quantity}';
    }
  }

  Color _getMovementColor(MovementType type) {
    switch (type) {
      case MovementType.entry:
        return Colors.green;
      case MovementType.exit:
        return Colors.red;
      case MovementType.adjustment:
        return Colors.blue;
    }
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