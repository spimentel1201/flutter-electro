import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/inventory_movement.dart';
import 'package:electro_workshop/services/inventory_movement_service.dart';

class InventoryMovementFormScreen extends StatefulWidget {
  final int itemId;
  final String itemName;

  const InventoryMovementFormScreen({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  _InventoryMovementFormScreenState createState() => _InventoryMovementFormScreenState();
}

class _InventoryMovementFormScreenState extends State<InventoryMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final InventoryMovementService _movementService = GetIt.instance<InventoryMovementService>();
  
  MovementType _selectedType = MovementType.entry;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _performedByController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _performedByController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final movement = InventoryMovement(
        id: 0, // ID will be assigned by the backend
        inventoryItemId: widget.itemId,
        itemName: widget.itemName,
        type: _selectedType,
        quantity: int.parse(_quantityController.text),
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
        performedBy: _performedByController.text.isNotEmpty ? _performedByController.text : null,
        timestamp: DateTime.now(),
        priceAtMovement: _priceController.text.isNotEmpty ? double.parse(_priceController.text) : null,
      );

      await _movementService.createMovement(movement);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save movement: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('Add Movement'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
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
                            Text(
                              'Item: ${widget.itemName}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16.0),
                            const Text('Movement Type'),
                            const SizedBox(height: 8.0),
                            _buildMovementTypeSelector(),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a quantity';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (int.parse(value) <= 0) {
                                  return 'Quantity must be greater than zero';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _reasonController,
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                                border: OutlineInputBorder(),
                                hintText: 'Why is this movement happening?',
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _performedByController,
                              decoration: const InputDecoration(
                                labelText: 'Performed By',
                                border: OutlineInputBorder(),
                                hintText: 'Who is performing this movement?',
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price at Movement',
                                border: OutlineInputBorder(),
                                prefixText: r'$',
                                hintText: 'Optional',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveMovement,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                        ),
                        child: const Text('Save Movement'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMovementTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildMovementTypeOption(
            type: MovementType.entry,
            title: 'Entry',
            icon: Icons.add_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMovementTypeOption(
            type: MovementType.exit,
            title: 'Exit',
            icon: Icons.remove_circle,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMovementTypeOption(
            type: MovementType.adjustment,
            title: 'Adjustment',
            icon: Icons.sync,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMovementTypeOption({
    required MovementType type,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28.0),
            const SizedBox(height: 4.0),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}