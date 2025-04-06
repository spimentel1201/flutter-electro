import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';

class QuoteConversionScreen extends StatefulWidget {
  final int quoteId;

  const QuoteConversionScreen({super.key, required this.quoteId});

  @override
  State<QuoteConversionScreen> createState() => _QuoteConversionScreenState();
}

class _QuoteConversionScreenState extends State<QuoteConversionScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  Quote? _quote;
  bool _isLoading = true;
  bool _isConverting = false;
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sendNotification = true;
  bool _createInvoice = true;
  bool _assignTechnician = false;
  String? _selectedTechnician;
  final List<String> _technicians = ['Técnico 1', 'Técnico 2', 'Técnico 3']; // En una app real, esto vendría de una API

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quote = await _quoteService.getQuoteById(widget.quoteId);
      setState(() {
        _quote = quote;
        _isLoading = false;
      });

      // Verificar si el presupuesto está aprobado
      if (quote.status != QuoteStatus.approved) {
        _showErrorSnackBar('Solo se pueden convertir presupuestos aprobados');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar el presupuesto: ${e.toString()}');
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

  Future<void> _convertQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quote == null) return;

    if (_quote!.status != QuoteStatus.approved) {
      _showErrorSnackBar('Solo se pueden convertir presupuestos aprobados');
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      // En una implementación real, enviaríamos todos los parámetros adicionales
      final result = await _quoteService.convertQuoteToInvoice(_quote!.id);
      
      _showSuccessSnackBar(
        'Presupuesto convertido a orden de reparación correctamente. ID: ${result['repairOrderId']}',
      );
      
      // Esperar un momento para que el usuario vea el mensaje de éxito
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pop(true); // Volver a la pantalla anterior con resultado exitoso
      }
    } catch (e) {
      _showErrorSnackBar('Error al convertir el presupuesto: ${e.toString()}');
      setState(() {
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convertir Presupuesto #${widget.quoteId}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quote == null
              ? const Center(child: Text('No se pudo cargar el presupuesto'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del presupuesto
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Información del Presupuesto',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'Cliente',
                                  _quote!.repairOrder.customer.name,
                                ),
                                _buildInfoRow(
                                  'Dispositivo',
                                  '${_quote!.repairOrder.deviceType} ${_quote!.repairOrder.brand} ${_quote!.repairOrder.model}',
                                ),
                                _buildInfoRow(
                                  'Total',
                                  NumberFormat.currency(locale: 'es_ES', symbol: '€')
                                      .format(_quote!.total),
                                ),
                                _buildInfoRow(
                                  'Estado',
                                  _getStatusText(_quote!.status),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Opciones de conversión
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Opciones de Conversión',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Enviar notificación al cliente'),
                                  subtitle: const Text(
                                      'Se enviará un email al cliente informando que su presupuesto ha sido aprobado y se ha iniciado la reparación'),
                                  value: _sendNotification,
                                  onChanged: (value) {
                                    setState(() {
                                      _sendNotification = value;
                                    });
                                  },
                                ),
                                const Divider(),
                                SwitchListTile(
                                  title: const Text('Crear factura preliminar'),
                                  subtitle: const Text(
                                      'Se creará una factura preliminar basada en el presupuesto'),
                                  value: _createInvoice,
                                  onChanged: (value) {
                                    setState(() {
                                      _createInvoice = value;
                                    });
                                  },
                                ),
                                const Divider(),
                                SwitchListTile(
                                  title: const Text('Asignar técnico'),
                                  subtitle: const Text(
                                      'Asignar un técnico para realizar la reparación'),
                                  value: _assignTechnician,
                                  onChanged: (value) {
                                    setState(() {
                                      _assignTechnician = value;
                                    });
                                  },
                                ),
                                if (_assignTechnician) ...[                                  
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Seleccionar técnico',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedTechnician,
                                    items: _technicians.map((String technician) {
                                      return DropdownMenuItem<String>(
                                        value: technician,
                                        child: Text(technician),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedTechnician = newValue;
                                      });
                                    },
                                    validator: _assignTechnician
                                        ? (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Por favor seleccione un técnico';
                                            }
                                            return null;
                                          }
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Notas adicionales
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notas Adicionales',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _notesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Notas para la orden de reparación',
                                    hintText: 'Instrucciones especiales, comentarios, etc.',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Botón de conversión
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.transform),
                            label: const Text('Convertir a Orden de Reparación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed: _isConverting ? null : _convertQuote,
                          ),
                        ),

                        if (_isConverting)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _getStatusText(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft:
        return 'Borrador';
      case QuoteStatus.pending:
        return 'Pendiente';
      case QuoteStatus.approved:
        return 'Aprobado';
      case QuoteStatus.rejected:
        return 'Rechazado';
      case QuoteStatus.expired:
        return 'Expirado';
      default:
        return 'Desconocido';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}