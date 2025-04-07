import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/services/customer_service.dart';

class ClientFormScreen extends StatefulWidget {
  final Customer? client;

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  _ClientFormScreenState createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ClientService _clientService = ClientService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _documentTypeController = TextEditingController();
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.client != null;
    
    if (_isEditing) {
      _nameController.text = widget.client!.name;
      _emailController.text = widget.client!.email ?? '';
      _phoneController.text = widget.client!.phone;
      _documentTypeController.text = widget.client!.documentType;
      _documentNumberController.text = widget.client!.documentNumber;
      _addressController.text = widget.client!.address ?? '';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final now = DateTime.now();
      final Customer client = Customer(
        id: _isEditing ? widget.client!.id : '',  // ID will be assigned by backend for new clients
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        phone: _phoneController.text,
        documentType: _documentTypeController.text,
        documentNumber: _documentNumberController.text,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        createdAt: _isEditing ? widget.client!.createdAt : now,
        updatedAt: now,
      );
      
      if (_isEditing) {
        await _clientService.updateClient(client);
      } else {
        await _clientService.createClient(client);
      }
      
      if (mounted) {
        Navigator.pop(context, true);  // Return true to indicate success
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save client: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Client' : 'Add Client'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Simple email validation
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _documentTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Document Type (DNI, RUC, etc.)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a document type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _documentNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Document Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a document number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _saveClient,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(_isEditing ? 'Update Client' : 'Add Client'),
                      ),
                    ),
                  ],
                ),
              ),
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
}