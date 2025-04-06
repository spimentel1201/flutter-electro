import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/product.dart';
import 'package:electro_workshop/services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  
  const ProductFormScreen({Key? key, this.product}) : super(key: key);
  
  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final ProductService _productService = GetIt.instance<ProductService>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;
    
    if (_isEditing) {
      // Populate form with existing product data
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _categoryController.text = widget.product!.category;
      _priceController.text = widget.product!.price.toString();
      _costController.text = widget.product!.cost.toString();
      _stockController.text = widget.product!.stock.toString();
      _isActive = widget.product!.isActive;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }
  
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final product = Product(
        id: _isEditing ? widget.product!.id : 0, // ID will be assigned by backend for new products
        name: _nameController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text),
        cost: double.parse(_costController.text),
        stock: int.parse(_stockController.text),
        isActive: _isActive,
      );
      
      if (_isEditing) {
        await _productService.updateProduct(product);
      } else {
        await _productService.createProduct(product);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al guardar producto: ${e.toString()}');
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
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
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
                    // Información básica
                    _buildSectionTitle('Información Básica'),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        hintText: 'Ingrese el nombre del producto',
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        hintText: 'Ingrese la categoría del producto',
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una categoría';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText: 'Ingrese la descripción del producto',
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                    
                    // Información de precios
                    _buildSectionTitle('Precios'),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Precio de venta *',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un precio';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Ingrese un número válido';
                              }
                              if (double.parse(value) <= 0) {
                                return 'El precio debe ser mayor a 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: const InputDecoration(
                              labelText: 'Costo *',
                              hintText: '0.00',
                              prefixIcon: Icon(Icons.money_off),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d\.]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese un costo';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Ingrese un número válido';
                              }
                              if (double.parse(value) < 0) {
                                return 'El costo no puede ser negativo';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    
                    // Información de inventario
                    _buildSectionTitle('Inventario'),
                    
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock *',
                        hintText: '0',
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una cantidad';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Ingrese un número válido';
                        }
                        if (int.parse(value) < 0) {
                          return 'El stock no puede ser negativo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    
                    SwitchListTile(
                      title: const Text('Producto activo'),
                      subtitle: const Text('Los productos inactivos no aparecerán en el catálogo'),
                      value: _isActive,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 32.0),
                    
                    // Botones de acción
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveProduct,
                        icon: const Icon(Icons.save),
                        label: Text(_isEditing ? 'Actualizar Producto' : 'Crear Producto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8.0),
      ],
    );
  }
}