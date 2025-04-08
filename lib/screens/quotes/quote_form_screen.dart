import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/services/customer_service.dart';
import 'package:electro_workshop/services/user_service.dart';
import 'package:electro_workshop/services/repair_service.dart';
class QuoteFormScreen extends StatefulWidget {
  final Quote? quote;
  final String? repairOrderId;

  const QuoteFormScreen({Key? key, this.quote, this.repairOrderId}) : super(key: key);

  @override
  _QuoteFormScreenState createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  final CustomerService _customerService = GetIt.instance<CustomerService>();
  final UserService _userService = GetIt.instance<UserService>();
  final RepairService _repairOrderService = GetIt.instance<RepairService>();
  
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isEditing = false;
  
  Customer? _selectedCustomer;
  User? _selectedTechnician;
  RepairOrder? _selectedRepairOrder;
  List<Customer> _customers = [];
  List<User> _technicians = [];
  List<RepairOrder> _repairOrders = [];
  List<QuoteItem> _items = [];
  
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.quote != null;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final customersResponse = _customerService.getAllCustomers();
      final techniciansResponse = _userService.getTechnicians();
      final repairOrdersResponse = _repairOrderService.getAllRepairOrders();
      
      final results = await Future.wait([customersResponse, techniciansResponse, repairOrdersResponse]);
      
      setState(() {
        _customers = results[0] as List<Customer>;
        _technicians = results[1] as List<User>;
        _repairOrders = results[2] as List<RepairOrder>;
        
        if (_isEditing && widget.quote != null) {
          _selectedCustomer = widget.quote!.customer;
          _selectedTechnician = widget.quote!.technician;
          _selectedRepairOrder = widget.quote!.repairOrder;
          _items = List.from(widget.quote!.items);
          _calculateTotal();
        } else if (widget.repairOrderId != null) {
          _selectedRepairOrder = _repairOrders.firstWhere(
            (order) => order.id == widget.repairOrderId,
            orElse: () => _repairOrders.first,
          );
          
          if (_selectedRepairOrder != null) {
            _selectedCustomer = _customers.firstWhere(
              (customer) => customer.id == _selectedRepairOrder!.customerId,
              orElse: () => _customers.first,
            );
          }
        }
        
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });
      _showErrorSnackBar('Failed to load initial data: ${e.toString()}');
    }
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _items) {
      total += item.total;
    }
    
    setState(() {
      _totalAmount = total;
    });
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }
    
    if (_selectedTechnician == null) {
      _showErrorSnackBar('Please select a technician');
      return;
    }
    
    if (_selectedRepairOrder == null) {
      _showErrorSnackBar('Please select a repair order');
      return;
    }
    
    if (_items.isEmpty) {
      _showErrorSnackBar('Please add at least one item to the quote');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final now = DateTime.now();
      
      // Create a new Quote object with the form data
      final Quote quote = Quote(
        id: _isEditing ? widget.quote!.id : '',
        repairOrderId: _selectedRepairOrder!.id,
        customerId: _selectedCustomer!.id,
        technicianId: _selectedTechnician!.id,
        status: _isEditing ? widget.quote!.status : QuoteStatus.PENDING,
        totalAmount: _totalAmount,
        createdAt: _isEditing ? widget.quote!.createdAt : now,
        updatedAt: now,
        items: _items,
        repairOrder: _selectedRepairOrder,
        customer: _selectedCustomer,
        technician: _selectedTechnician,
      );
      
      if (_isEditing) {
        await _quoteService.updateQuote(quote);
      } else {
        await _quoteService.createQuote(quote);
      }
      
      if (mounted) {
        Navigator.pop(context, true);  // Return true to indicate success
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save quote: ${e.toString()}');
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

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddItemBottomSheet(
        onItemAdded: (item) {
          setState(() {
            _items.add(item);
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _editItem(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddItemBottomSheet(
        initialItem: _items[index],
        onItemAdded: (item) {
          setState(() {
            _items[index] = item;
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quote' : 'Create Quote'),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSelectionSection(),
                          const SizedBox(height: 24),
                          _buildItemsSection(),
                          const SizedBox(height: 24),
                          _buildTotalSection(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quote Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RepairOrder>(
              value: _selectedRepairOrder,
              decoration: const InputDecoration(
                labelText: 'Repair Order *',
                border: OutlineInputBorder(),
              ),
              items: _repairOrders.map((order) {
                return DropdownMenuItem<RepairOrder>(
                  value: order,
                  child: Text('Order #${order.id.substring(0, 8)} - ${order.description.substring(0, 20)}'),
                );
              }).toList(),
              onChanged: _isEditing ? null : (value) {
                setState(() {
                  _selectedRepairOrder = value;
                  if (value != null) {
                    _selectedCustomer = _customers.firstWhere(
                      (customer) => customer.id == value.customerId,
                      orElse: () => _customers.first,
                    );
                  }
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a repair order';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              decoration: const InputDecoration(
                labelText: 'Customer *',
                border: OutlineInputBorder(),
              ),
              items: _customers.map((customer) {
                return DropdownMenuItem<Customer>(
                  value: customer,
                  child: Text(customer.name),
                );
              }).toList(),
              onChanged: _isEditing ? null : (value) {
                setState(() {
                  _selectedCustomer = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a customer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<User>(
              value: _selectedTechnician,
              decoration: const InputDecoration(
                labelText: 'Technician *',
                border: OutlineInputBorder(),
              ),
              items: _technicians.map((technician) {
                return DropdownMenuItem<User>(
                  value: technician,
                  child: Text(technician.firstName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTechnician = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a technician';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No items added yet'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity} x \$${item.price.toStringAsFixed(2)}'),
                          Text(
                            item.isLabor ? 'Labor' : 'Part',
                            style: TextStyle(
                              color: item.isLabor ? Colors.blue : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editItem(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Amount:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveQuote,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isEditing ? 'Update Quote' : 'Create Quote',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet for adding/editing items
class _AddItemBottomSheet extends StatefulWidget {
  final QuoteItem? initialItem;
  final Function(QuoteItem) onItemAdded;

  const _AddItemBottomSheet({
    this.initialItem,
    required this.onItemAdded,
  });

  @override
  _AddItemBottomSheetState createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<_AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLabor = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialItem != null) {
      _descriptionController.text = widget.initialItem!.description;
      _quantityController.text = widget.initialItem!.quantity.toString();
      _priceController.text = widget.initialItem!.price.toString();
      _isLabor = widget.initialItem!.isLabor;
    } else {
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final now = DateTime.now();
    final item = QuoteItem(
      id: widget.initialItem?.id ?? '',
      quoteId: widget.initialItem?.quoteId ?? '',
      description: _descriptionController.text,
      quantity: int.parse(_quantityController.text),
      price: double.parse(_priceController.text),
      isLabor: _isLabor,
      createdAt: widget.initialItem?.createdAt ?? now,
      updatedAt: now,
    );
    
    widget.onItemAdded(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialItem != null ? 'Edit Item' : 'Add Item',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Invalid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Labor'),
              value: _isLabor,
              onChanged: (value) {
                setState(() {
                  _isLabor = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addItem,
                  child: Text(widget.initialItem != null ? 'Update' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}