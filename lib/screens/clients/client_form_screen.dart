import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/services/customer_service.dart';

class ClientFormScreen extends StatefulWidget {
  final bool isEditing;
  final Customer? customer;

  const ClientFormScreen({super.key, required this.isEditing, this.customer});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final CustomerService _customerService = GetIt.instance<CustomerService>();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedDocumentType = 'DNI';
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _documentTypes = ['DNI', 'RUC'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.customer != null) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() {
    final customer = widget.customer!;
    _nameController.text = customer.name;
    _emailController.text = customer.email;
    _phoneController.text = customer.phone;
    _documentNumberController.text = customer.documentNumber ?? '';
    _addressController.text = customer.address ?? '';
    _notesController.text = customer.notes ?? '';
    
    if (customer.documentType != null) {
      _selectedDocumentType = customer.documentType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerData = Customer(
        id: widget.isEditing ? widget.customer!.id : 0, // ID will be assigned by backend for new customers
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.isEmpty ? null : _documentNumberController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.isEditing ? widget.customer!.createdAt : DateTime.now(),
      );

      if (widget.isEditing) {
        await _customerService.updateCustomer(customerData);
        _showSuccessSnackBar('Cliente actualizado con éxito');
      } else {
        await _customerService.createCustomer(customerData);
        _showSuccessSnackBar('Cliente creado con éxito');
      }

      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al guardar el cliente: ${e.toString()}');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
        title: Text(widget.isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveCustomer,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                onChanged: () {
                  if (!_hasChanges) {
                    setState(() {
                      _hasChanges = true;
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Información Personal'),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDocumentSection(),
                    const SizedBox(height: 16),
                    _buildContactSection(),
                    const SizedBox(height: 16),
                    _buildAddressField(),
                    const SizedBox(height: 16),
                    _buildNotesField(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nombre completo',
        hintText: 'Ingrese el nombre completo',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese el nombre';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document Type Dropdown
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _selectedDocumentType,
            decoration: InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
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
                _hasChanges = true;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        // Document Number Field
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _documentNumberController,
            decoration: InputDecoration(
              labelText: 'Número de documento',
              hintText: _selectedDocumentType == 'DNI' ? '12345678' : '20123456789',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (_selectedDocumentType == 'DNI' && value.length != 8) {
                  return 'El DNI debe tener 8 dígitos';
                } else if (_selectedDocumentType == 'RUC' && value.length != 11) {
                  return 'El RUC debe tener 11 dígitos';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Teléfono',
            hintText: 'Ingrese el número de teléfono',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el teléfono';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'Ingrese el correo electrónico',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese el correo electrónico';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Por favor ingrese un correo electrónico válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: 'Dirección',
        hintText: 'Ingrese la dirección',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 2,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notas',
        hintText: 'Ingrese notas adicionales',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCustomer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'GUARDAR',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}