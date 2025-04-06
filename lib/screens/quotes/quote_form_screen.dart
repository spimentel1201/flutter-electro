import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/services/repair_service.dart';

class QuoteFormScreen extends StatefulWidget {
  final int? quoteId;
  final int? repairOrderId;

  const QuoteFormScreen({super.key, this.quoteId, this.repairOrderId});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  final RepairService _repairService = GetIt.instance<RepairService>();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();
  final _validUntilController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  Quote? _quote;
  RepairOrder? _selectedRepairOrder;
  List<RepairOrder> _repairOrders = [];
  List<QuoteItem> _quoteItems = [];
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.quoteId != null;
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar órdenes de reparación disponibles
      final repairOrders = await _repairService.getAllRepairOrders();
      setState(() {
        _repairOrders = repairOrders;
      });

      // Si estamos editando un presupuesto existente
      if (_isEditMode && widget.quoteId != null) {
        final quote = await _quoteService.getQuoteById(widget.quoteId!);
        setState(() {
          _quote = quote;
          _selectedRepairOrder = quote.repairOrder;
          _quoteItems = List.from(quote.items);
          _notesController.text = quote.notes ?? '';
          _discountController.text = quote.discount?.toString() ?? '';
          _taxController.text = quote.tax?.toString() ?? '';
          _validUntil = quote.validUntil;
          _validUntilController.text = DateFormat('dd/MM/yyyy').format(quote.validUntil);
        });
      } 
      // Si estamos creando un presupuesto desde una orden de reparación
      else if (widget.repairOrderId != null) {
        final repairOrder = await _repairService.getRepairOrderById(widget.repairOrderId!);
        setState(() {
          _selectedRepairOrder = repairOrder;
          _validUntilController.text = DateFormat('dd/MM/yyyy').format(_validUntil);
        });
      } else {
        _validUntilController.text = DateFormat('dd/MM/yyyy').format(_validUntil);
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar los datos: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _validUntil) {
      setState(() {
        _validUntil = picked;
        _validUntilController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _addQuoteItem() {
    showDialog(
      context: context,
      builder: (context) => _QuoteItemDialog(
        onItemAdded: (item) {
          setState(() {
            _quoteItems.add(item);
          });
        },
      ),
    );
  }

  void _editQuoteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _QuoteItemDialog(
        initialItem: _quoteItems[index],
        onItemAdded: (item) {
          setState(() {
            _quoteItems[index] = item;
          });
        },
      ),
    );
  }

  void _removeQuoteItem(int index) {
    setState(() {
      _quoteItems.removeAt(index);
    });
  }

  double _calculateSubtotal() {
    return _quoteItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _calculateDiscount() {
    final discount = double.tryParse(_discountController.text) ?? 0;
    return _calculateSubtotal() * (discount / 100);
  }

  double _calculateTax() {
    final tax = double.tryParse(_taxController.text) ?? 0;
    return (_calculateSubtotal() - _calculateDiscount()) * (tax / 100);
  }

  double _calculateTotal() {
    return _calculateSubtotal() - _calculateDiscount() + _calculateTax();
  }

  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRepairOrder == null) {
        _showErrorSnackBar('Debe seleccionar una orden de reparación');
        return;
      }

      if (_quoteItems.isEmpty) {
        _showErrorSnackBar('Debe agregar al menos un ítem al presupuesto');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Crear un usuario ficticio para el ejemplo (en una app real, sería el usuario actual)
        final currentUser = User(id: 1, name: 'Admin', email: 'admin@example.com', role: UserRole.admin, phone: '');

        // Crear o actualizar el presupuesto
        if (_isEditMode && _quote != null) {
          // Actualizar presupuesto existente
          final updatedQuote = _quote!.copyWith(
            repairOrder: _selectedRepairOrder!,
            items: _quoteItems,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            discount: _discountController.text.isEmpty ? null : double.parse(_discountController.text),
            tax: _taxController.text.isEmpty ? null : double.parse(_taxController.text),
            validUntil: _validUntil,
          );

          await _quoteService.updateQuote(updatedQuote);
          _showSuccessSnackBar('Presupuesto actualizado correctamente');
        } else {
          // Crear nuevo presupuesto
          final newQuote = Quote(
            id: 0, // El ID será asignado por el backend
            repairOrder: _selectedRepairOrder!,
            items: _quoteItems,
            status: QuoteStatus.draft,
            createdAt: DateTime.now(),
            validUntil: _validUntil,
            createdBy: currentUser,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            discount: _discountController.text.isEmpty ? null : double.parse(_discountController.text),
            tax: _taxController.text.isEmpty ? null : double.parse(_taxController.text),
          );

          await _quoteService.createQuote(newQuote);
          _showSuccessSnackBar('Presupuesto creado correctamente');
        }

        // Volver a la pantalla anterior con resultado exitoso
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        _showErrorSnackBar('Error al guardar el presupuesto: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Presupuesto' : 'Nuevo Presupuesto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveQuote,
          ),
        ],
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información General',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            DropdownButtonFormField<RepairOrder>(
                              decoration: const InputDecoration(
                                labelText: 'Orden de Reparación',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedRepairOrder,
                              items: _repairOrders.map((repairOrder) {
                                return DropdownMenuItem<RepairOrder>(
                                  value: repairOrder,
                                  child: Text(
                                    '#${repairOrder.id} - ${repairOrder.customer.name} - ${repairOrder.deviceType} ${repairOrder.brand} ${repairOrder.model}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: _isEditMode
                                  ? null // No permitir cambiar la orden en modo edición
                                  : (RepairOrder? newValue) {
                                      setState(() {
                                        _selectedRepairOrder = newValue;
                                      });
                                    },
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor seleccione una orden de reparación';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _validUntilController,
                              decoration: InputDecoration(
                                labelText: 'Válido hasta',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () => _selectDate(context),
                                ),
                              ),
                              readOnly: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese una fecha de validez';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notas',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ítems del Presupuesto',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar Ítem'),
                                  onPressed: _addQuoteItem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            _quoteItems.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No hay ítems en el presupuesto',
                                        style: TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _quoteItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _quoteItems[index];
                                      return ListTile(
                                        title: Text(item.description),
                                        subtitle: Text(
                                          item.isLabor ? 'Mano de obra' : 'Repuesto',
                                          style: TextStyle(
                                            color: item.isLabor ? Colors.blue : Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${item.quantity} x ${currencyFormat.format(item.price)} = ${currencyFormat.format(item.total)}',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20),
                                              onPressed: () => _editQuoteItem(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                              onPressed: () => _removeQuoteItem(index),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumen',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _discountController,
                                    decoration: const InputDecoration(
                                      labelText: 'Descuento (%)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _taxController,
                                    decoration: const InputDecoration(
                                      labelText: 'Impuestos (%)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPriceRow('Subtotal', currencyFormat.format(_calculateSubtotal())),
                            if (_discountController.text.isNotEmpty && double.tryParse(_discountController.text) != null && double.tryParse(_discountController.text)! > 0)
                              _buildPriceRow(
                                'Descuento (${_discountController.text}%)',
                                '- ${currencyFormat.format(_calculateDiscount())}',
                              ),
                            if (_taxController.text.isNotEmpty && double.tryParse(_taxController.text) != null && double.tryParse(_taxController.text)! > 0)
                              _buildPriceRow(
                                'Impuestos (${_taxController.text}%)',
                                '+ ${currencyFormat.format(_calculateTax())}',
                              ),
                            const Divider(),
                            _buildPriceRow(
                              'Total',
                              currencyFormat.format(_calculateTotal()),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteItemDialog extends StatefulWidget {
  final QuoteItem? initialItem;
  final Function(QuoteItem) onItemAdded;

  const _QuoteItemDialog({
    this.initialItem,
    required this.onItemAdded,
  });

  @override
  State<_QuoteItemDialog> createState() => _QuoteItemDialogState();
}

class _QuoteItemDialogState extends State<_QuoteItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLabor = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _descriptionController.text = widget.initialItem!.description;
      _priceController.text = widget.initialItem!.price.toString();
      _quantityController.text = widget.initialItem!.quantity.toString();
      _isLabor = widget.initialItem!.isLabor;
    } else {
      _quantityController.text = '1'; // Valor por defecto
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final item = QuoteItem(
        id: widget.initialItem?.id ?? 0, // El ID será asignado por el backend si es nuevo
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        isLabor: _isLabor,
      );

      widget.onItemAdded(item);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem == null ? 'Agregar Ítem' : 'Editar Ítem'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una cantidad';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número entero';
                  }
                  if (int.parse(value) <= 0) {
                    return 'La cantidad debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Mano de obra'),
                value: _isLabor,
                onChanged: (value) {
                  setState(() {
                    _isLabor = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveItem,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}