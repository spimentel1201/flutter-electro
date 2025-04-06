import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';

class QuoteApprovalScreen extends StatefulWidget {
  final int quoteId;
  final String? accessToken;

  const QuoteApprovalScreen({
    super.key, 
    required this.quoteId, 
    this.accessToken,
  });

  @override
  State<QuoteApprovalScreen> createState() => _QuoteApprovalScreenState();
}

class _QuoteApprovalScreenState extends State<QuoteApprovalScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  Quote? _quote;
  bool _isLoading = true;
  bool _isSubmitting = false;
  final _commentController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // En una implementación real, aquí verificaríamos el token de acceso
      // para asegurarnos de que el cliente tiene permiso para ver este presupuesto
      final quote = await _quoteService.getQuoteById(widget.quoteId);
      
      // Verificar si el presupuesto ya fue aprobado o rechazado
      if (quote.status == QuoteStatus.approved || quote.status == QuoteStatus.rejected) {
        setState(() {
          _errorMessage = 'Este presupuesto ya ha sido ${quote.status == QuoteStatus.approved ? "aprobado" : "rechazado"}';
        });
      }
      
      // Verificar si el presupuesto ha expirado
      if (quote.status == QuoteStatus.expired || quote.validUntil.isBefore(DateTime.now())) {
        setState(() {
          _errorMessage = 'Este presupuesto ha expirado';
        });
      }
      
      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar el presupuesto: ${e.toString()}';
      });
    }
  }

  Future<void> _approveQuote() async {
    await _updateQuoteStatus(QuoteStatus.approved);
  }

  Future<void> _rejectQuote() async {
    await _updateQuoteStatus(QuoteStatus.rejected);
  }

  Future<void> _updateQuoteStatus(QuoteStatus status) async {
    if (_quote == null) return;

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == QuoteStatus.approved ? 'Aprobar Presupuesto' : 'Rechazar Presupuesto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status == QuoteStatus.approved
                  ? '¿Está seguro de que desea aprobar este presupuesto?'
                  : '¿Está seguro de que desea rechazar este presupuesto?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comentarios (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == QuoteStatus.approved ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(status == QuoteStatus.approved ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // En una implementación real, aquí enviaríamos el token de acceso
      // y los comentarios junto con la actualización de estado
      await _quoteService.updateQuoteStatus(_quote!.id, status);
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == QuoteStatus.approved
                  ? 'Presupuesto aprobado correctamente'
                  : 'Presupuesto rechazado correctamente',
            ),
            backgroundColor: status == QuoteStatus.approved ? Colors.green : Colors.red,
          ),
        );
        
        // Recargar el presupuesto para mostrar el nuevo estado
        _loadQuote();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado del presupuesto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Presupuesto #${widget.quoteId}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Volver'),
                        ),
                      ],
                    ),
                  ),
                )
              : _quote == null
                  ? const Center(child: Text('No se pudo cargar el presupuesto'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado con información básica
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Presupuesto #${_quote!.id}',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                      _buildStatusChip(_quote!.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fecha: ${DateFormat('dd/MM/yyyy').format(_quote!.createdAt)}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    'Válido hasta: ${DateFormat('dd/MM/yyyy').format(_quote!.validUntil)}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Información del cliente y dispositivo
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Información del Cliente',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Nombre', _quote!.repairOrder.customer.name),
                                  _buildInfoRow('Teléfono', _quote!.repairOrder.customer.phone),
                                  _buildInfoRow('Email', _quote!.repairOrder.customer.email),
                                  const Divider(),
                                  Text(
                                    'Información del Dispositivo',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Tipo', _quote!.repairOrder.deviceType),
                                  _buildInfoRow('Marca', _quote!.repairOrder.brand),
                                  _buildInfoRow('Modelo', _quote!.repairOrder.model),
                                  if (_quote!.repairOrder.serialNumber != null)
                                    _buildInfoRow('Nº Serie', _quote!.repairOrder.serialNumber!),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Detalles del presupuesto
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detalles del Presupuesto',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  // Tabla de ítems
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _quote!.items.length,
                                    itemBuilder: (context, index) {
                                      final item = _quote!.items[index];
                                      return ListTile(
                                        title: Text(item.description),
                                        subtitle: Text(
                                          '${item.quantity} x ${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(item.price)}',
                                        ),
                                        trailing: Text(
                                          NumberFormat.currency(locale: 'es_ES', symbol: '€').format(item.total),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        tileColor: item.isLabor ? Colors.blue.withOpacity(0.1) : null,
                                      );
                                    },
                                  ),
                                  const Divider(),
                                  // Resumen de precios
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                      children: [
                                        _buildPriceRow(
                                          'Subtotal',
                                          NumberFormat.currency(locale: 'es_ES', symbol: '€').format(_quote!.subtotal),
                                        ),
                                        if (_quote!.discount != null && _quote!.discount! > 0)
                                          _buildPriceRow(
                                            'Descuento (${_quote!.discount}%)',
                                            '- ${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(_quote!.discountAmount)}',
                                          ),
                                        if (_quote!.tax != null && _quote!.tax! > 0)
                                          _buildPriceRow(
                                            'Impuestos (${_quote!.tax}%)',
                                            '+ ${NumberFormat.currency(locale: 'es_ES', symbol: '€').format(_quote!.taxAmount)}',
                                          ),
                                        const Divider(),
                                        _buildPriceRow(
                                          'TOTAL',
                                          NumberFormat.currency(locale: 'es_ES', symbol: '€').format(_quote!.total),
                                          isBold: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notas
                          if (_quote!.notes != null && _quote!.notes!.isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notas',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(_quote!.notes!),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Botones de aprobación/rechazo
                          if (_quote!.status == QuoteStatus.pending)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Aprobar Presupuesto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: _isSubmitting ? null : _approveQuote,
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Rechazar Presupuesto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: _isSubmitting ? null : _rejectQuote,
                                ),
                              ],
                            ),

                          if (_isSubmitting)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusChip(QuoteStatus status) {
    Color color;
    String text;

    switch (status) {
      case QuoteStatus.draft:
        color = Colors.grey;
        text = 'Borrador';
        break;
      case QuoteStatus.pending:
        color = Colors.orange;
        text = 'Pendiente';
        break;
      case QuoteStatus.approved:
        color = Colors.green;
        text = 'Aprobado';
        break;
      case QuoteStatus.rejected:
        color = Colors.red;
        text = 'Rechazado';
        break;
      case QuoteStatus.expired:
        color = Colors.purple;
        text = 'Expirado';
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
    }

    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
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

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}