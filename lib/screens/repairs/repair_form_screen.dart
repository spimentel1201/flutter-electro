import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/models/repair_order_item.dart';
import 'package:electro_workshop/services/repair_service.dart';
import 'package:electro_workshop/services/customer_service.dart';
import 'package:electro_workshop/services/user_service.dart';

class RepairFormScreen extends StatefulWidget {
  final String? repairId;

  const RepairFormScreen({super.key, this.repairId});

  @override
  State<RepairFormScreen> createState() => _RepairFormScreenState();
}

class _RepairFormScreenState extends State<RepairFormScreen> {
  final RepairService _repairService = GetIt.instance.get<RepairService>();
  final CustomerService _customerService = GetIt.instance.get<CustomerService>();
  final UserService _userService = GetIt.instance.get<UserService>();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditMode = false;
  RepairOrder? _repair;
  
  // Form controllers
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _initialReviewCostController = TextEditingController();
  final _totalCostController = TextEditingController();
  
  // Selected values
  String? _selectedCustomerId;
  String? _selectedTechnicianId;
  String _selectedStatus = RepairOrderStatus.RECEIVED;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  // Lists for dropdowns
  List<Customer> _customers = [];
  List<User> _technicians = [];
  
  // Device items
  List<RepairOrderItem> _deviceItems = [];
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.repairId != null;
    _loadFormData();
  }
  
  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load customers and technicians
      _customers = await _customerService.getAllCustomers();
      _technicians = await _userService.getTechnicians();
      
      if (_isEditMode) {
        // Load repair data if in edit mode
        _repair = await _repairService.getRepairOrderById(widget.repairId!);
        
        // Set form values
        _descriptionController.text = _repair!.description;
        _notesController.text = _repair!.notes ?? '';
        _initialReviewCostController.text = _repair!.initialReviewCost.toString();
        _totalCostController.text = _repair!.totalCost.toString();
        
        _selectedCustomerId = _repair!.customerId;
        _selectedTechnicianId = _repair!.technicianId;
        _selectedStatus = _repair!.status;
        _startDate = _repair!.startDate;
        _endDate = _repair!.endDate;
        
        _deviceItems = List.from(_repair!.items);
      } else {
        // Initialize with at least one device item in create mode
        _deviceItems.add(RepairOrderItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          repairOrderId: '',
          deviceType: '',
          brand: '',
          model: '',
          serialNumber: '',
          problemDescription: '',
          accessories: [],
          quantity: 1,
          price: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveRepair() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate at least one device
    if (_deviceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos un dispositivo')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final initialReviewCost = double.tryParse(_initialReviewCostController.text) ?? 0.0;
      final totalCost = double.tryParse(_totalCostController.text) ?? 0.0;
      
      if (_isEditMode) {
        // Update existing repair
        await _repairService.updateRepairOrder(
          RepairOrder(
            id: widget.repairId!,
            customerId: _selectedCustomerId!,
            technicianId: _selectedTechnicianId!,
            status: _selectedStatus,
            description: _descriptionController.text,
            notes: _notesController.text,
            initialReviewCost: initialReviewCost,
            totalCost: totalCost,
            startDate: _startDate,
            endDate: _endDate,
            createdAt: _repair?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            items: _deviceItems.map((item) => RepairOrderItem(
              id: item.id,
              repairOrderId: widget.repairId!,
              productId: item.productId,
              deviceType: item.deviceType,
              brand: item.brand,
              model: item.model,
              serialNumber: item.serialNumber,
              problemDescription: item.problemDescription,
              accessories: item.accessories,
              quantity: item.quantity,
              price: item.price,
              createdAt: item.createdAt,
              updatedAt: DateTime.now(),
            )).toList(),
          ),
          widget.repairId!, // Adding the second required argument - the repair ID
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden de reparación actualizada correctamente')),
        );
      } else {
        // Create new repair
        await _repairService.createRepairOrder(
          RepairOrder(
            id: '', // ID will be generated by the backend
            customerId: _selectedCustomerId!,
            technicianId: _selectedTechnicianId!,
            status: _selectedStatus,
            description: _descriptionController.text,
            notes: _notesController.text,
            initialReviewCost: initialReviewCost,
            totalCost: totalCost,
            startDate: _startDate,
            endDate: _endDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            items: _deviceItems.map((item) => RepairOrderItem(
              id: item.id,
              repairOrderId: '',
              productId: item.productId,
              deviceType: item.deviceType,
              brand: item.brand,
              model: item.model,
              serialNumber: item.serialNumber,
              problemDescription: item.problemDescription,
              accessories: item.accessories,
              quantity: item.quantity,
              price: item.price,
              createdAt: item.createdAt,
              updatedAt: DateTime.now(),
            )).toList(),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden de reparación creada correctamente')),
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de que desea eliminar esta orden de reparación? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _repairService.deleteRepairOrder(widget.repairId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden de reparación eliminada correctamente')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Reparación' : 'Nueva Reparación'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRepair,
            child: Text(_isEditMode ? 'Actualizar' : 'Crear'),
          ),
        ),
      ),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSection(),
            const SizedBox(height: 16),
            _buildTechnicianSection(),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildDetailsSection(),
            const SizedBox(height: 16),
            _buildDatesSection(),
            const SizedBox(height: 16),
            _buildCostsSection(),
            const SizedBox(height: 24),
            _buildDevicesSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Seleccionar Cliente',
                border: OutlineInputBorder(),
              ),
              value: _selectedCustomerId,
              items: _customers.map((customer) {
                return DropdownMenuItem<String>(
                  value: customer.id,
                  child: Text('${customer.name} (${customer.phone})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCustomerId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor seleccione un cliente';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to customer creation screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función para crear cliente en desarrollo')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Cliente'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTechnicianSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Técnico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Seleccionar Técnico',
                border: OutlineInputBorder(),
              ),
              value: _selectedTechnicianId,
              items: _technicians.map((technician) {
                return DropdownMenuItem<String>(
                  value: technician.id,
                  child: Text(technician.firstName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTechnicianId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor seleccione un técnico';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Estado de la reparación',
                border: OutlineInputBorder(),
              ),
              value: _selectedStatus,
              items: [
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.RECEIVED,
                  child: Text(_getStatusText(RepairOrderStatus.RECEIVED)),
                ),
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.DIAGNOSED,
                  child: Text(_getStatusText(RepairOrderStatus.DIAGNOSED)),
                ),
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.IN_PROGRESS,
                  child: Text(_getStatusText(RepairOrderStatus.IN_PROGRESS)),
                ),
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.WAITING_FOR_PARTS,
                  child: Text(_getStatusText(RepairOrderStatus.WAITING_FOR_PARTS)),
                ),
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.COMPLETED,
                  child: Text(_getStatusText(RepairOrderStatus.COMPLETED)),
                ),
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.DELIVERED,
                  child: Text(_getStatusText(RepairOrderStatus.DELIVERED)),
                ),
                DropdownMenuItem<String>(
                  value: RepairOrderStatus.CANCELLED,
                  child: Text(_getStatusText(RepairOrderStatus.CANCELLED)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDatesSection() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fechas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Fecha de inicio'),
                    subtitle: Text(dateFormat.format(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fecha de finalización'),
                    subtitle: Text(_endDate != null ? dateFormat.format(_endDate!) : 'No establecida'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCostsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Costos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _initialReviewCostController,
              decoration: const InputDecoration(
                labelText: 'Costo de revisión inicial (€)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un costo';
                }
                if (double.tryParse(value) == null) {
                  return 'Por favor ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalCostController,
              decoration: const InputDecoration(
                labelText: 'Costo total (€)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un costo';
                }
                if (double.tryParse(value) == null) {
                  return 'Por favor ingrese un número válido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDevicesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dispositivos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _deviceItems.add(RepairOrderItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        repairOrderId: '',
                        deviceType: '',
                        brand: '',
                        model: '',
                        serialNumber: '',
                        problemDescription: '',
                        accessories: [],
                        quantity: 1,
                        price: 0.0,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Dispositivo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _deviceItems.length,
              itemBuilder: (context, index) {
                return _buildDeviceItemCard(index);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceItemCard(int index) {
    final device = _deviceItems[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dispositivo ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_deviceItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _deviceItems.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: device.deviceType,
              decoration: const InputDecoration(
                labelText: 'Tipo de dispositivo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el tipo de dispositivo';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _deviceItems[index] = _deviceItems[index].copyWith(deviceType: value);
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: device.brand,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la marca';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _deviceItems[index] = _deviceItems[index].copyWith(brand: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: device.model,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el modelo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _deviceItems[index] = _deviceItems[index].copyWith(model: value);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: device.serialNumber,
              decoration: const InputDecoration(
                labelText: 'Número de serie',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _deviceItems[index] = _deviceItems[index].copyWith(serialNumber: value);
                });
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: device.problemDescription,
              decoration: const InputDecoration(
                labelText: 'Problema',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el problema';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _deviceItems[index] = _deviceItems[index].copyWith(problemDescription: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return 'Recibido';
      case RepairOrderStatus.DIAGNOSED:
        return 'Diagnosticado';
      case RepairOrderStatus.IN_PROGRESS:
        return 'En progreso';
      case RepairOrderStatus.WAITING_FOR_PARTS:
        return 'Esperando piezas';
      case RepairOrderStatus.COMPLETED:
        return 'Completado';
      case RepairOrderStatus.DELIVERED:
        return 'Entregado';
      case RepairOrderStatus.CANCELLED:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _initialReviewCostController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }
}