import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/product.dart';
import 'package:electro_workshop/services/product_service.dart';
import 'package:electro_workshop/screens/products/product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  
  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);
  
  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = GetIt.instance<ProductService>();
  late Product _product;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }
  
  Future<void> _refreshProductDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedProduct = await _productService.getProductById(_product.id);
      setState(() {
        _product = updatedProduct;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar detalles del producto: ${e.toString()}');
    }
  }
  
  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar ${_product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _productService.deleteProduct(_product.id);
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al eliminar producto: ${e.toString()}');
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
        title: Text(_product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductFormScreen(product: _product),
                ),
              ).then((updated) {
                if (updated == true) {
                  _refreshProductDetails();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteProduct,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen o placeholder
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Información del producto
                  _buildInfoSection('Información General', [
                    _buildInfoRow('Nombre', _product.name),
                    _buildInfoRow('Categoría', _product.category),
                    _buildInfoRow('Descripción', _product.description),
                  ]),
                  
                  const SizedBox(height: 16.0),
                  
                  // Información de precios
                  _buildInfoSection('Precios', [
                    _buildInfoRow('Precio de venta', '\$${_product.price.toStringAsFixed(2)}'),
                    _buildInfoRow('Costo', '\$${_product.cost.toStringAsFixed(2)}'),
                    _buildInfoRow('Margen', '\$${(_product.price - _product.cost).toStringAsFixed(2)} (${((_product.price - _product.cost) / _product.price * 100).toStringAsFixed(1)}%)'),
                  ]),
                  
                  const SizedBox(height: 16.0),
                  
                  // Información de inventario
                  _buildInfoSection('Inventario', [
                    _buildInfoRow('Stock actual', _product.stock.toString(), 
                      valueColor: _product.stock > 0 ? Colors.green : Colors.red),
                    _buildInfoRow('Estado', _product.isActive ? 'Activo' : 'Inactivo',
                      valueColor: _product.isActive ? Colors.green : Colors.red),
                  ]),
                  
                  const SizedBox(height: 32.0),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductFormScreen(product: _product),
                            ),
                          ).then((updated) {
                            if (updated == true) {
                              _refreshProductDetails();
                            }
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _deleteProduct,
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoSection(String title, List<Widget> children) {
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
        ...children,
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}