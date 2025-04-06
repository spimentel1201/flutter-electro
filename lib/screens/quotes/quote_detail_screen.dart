import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/services/repair_service.dart';
import 'package:electro_workshop/screens/quotes/quote_form_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_template_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_share_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_conversion_screen.dart';

class QuoteDetailScreen extends StatefulWidget {
  final int quoteId;

  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  final RepairService _repairService = GetIt.instance<RepairService>();
  Quote? _quote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
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

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.draft:
        return Colors.grey;
      case QuoteStatus.pending:
        return Colors.orange;
      case QuoteStatus.approved:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.expired:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _sendQuoteByEmail() async {
    if (_quote == null) return;

    // Redirigir a la pantalla de compartir para más opciones
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteShareScreen(quoteId: _quote!.id),
      ),
    );
  }

  Future<void> _sendQuoteByWhatsApp() async {
    if (_quote == null) return;

    // Redirigir a la pantalla de compartir para más opciones
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteShareScreen(quoteId: _quote!.id),
      ),
    );
  }

  Future<void> _updateQuoteStatus(QuoteStatus newStatus) async {
    if (_quote == null) return;

    try {
      await _quoteService.updateQuoteStatus(_quote!.id, newStatus);
      _loadQuote();
      _showSuccessSnackBar('Estado del presupuesto actualizado correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al actualizar el estado del presupuesto: ${e.toString()}');
    }
  }

  Future<void> _convertToRepairOrder() async {
    if (_quote == null) return;

    if (_quote!.status != QuoteStatus.approved) {
      _showErrorSnackBar('Solo se pueden convertir presupuestos aprobados');
      return;
    }

    // Navegar a la pantalla de conversión para más opciones
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteConversionScreen(quoteId: _quote!.id),
      ),
    );
    
    if (result == true) {
      // Si la conversión fue exitosa, volver a la pantalla anterior
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Presupuesto #${widget.quoteId}'),
        actions: [
          if (_quote != null && _quote!.status != QuoteStatus.draft) ...[            
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Imprimir presupuesto',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuoteTemplateScreen(quoteId: _quote!.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartir presupuesto',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuoteShareScreen(quoteId: _quote!.id),
                  ),
                );
              },
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuoteFormScreen(quoteId: widget.quoteId),
                  ),
                );
                if (result == true) {
                  _loadQuote();
                }
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quote == null
              ? const Center(child: Text('No se encontró el presupuesto'))
              : _buildQuoteDetails(),
      bottomNavigationBar: _quote == null
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_quote!.status == QuoteStatus.draft || _quote!.status == QuoteStatus.pending)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.email),
                        label: const Text('Email'),
                        onPressed: _sendQuoteByEmail,
                      ),
                    if (_quote!.status == QuoteStatus.draft || _quote!.status == QuoteStatus.pending)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.message),
                        label: const Text('WhatsApp'),
                        onPressed: _sendQuoteByWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (_quote!.status == QuoteStatus.approved)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.build),
                        label: const Text('Convertir'),
                        onPressed: _convertToRepairOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuoteDetails() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return SingleChildScrollView(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Información General',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_quote!.status),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getStatusText(_quote!.status),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('Cliente', _quote!.repairOrder.customer.name),
                  _buildInfoRow('Dispositivo', '${_quote!.repairOrder.deviceType} - ${_quote!.repairOrder.brand} ${_quote!.repairOrder.model}'),
                  _buildInfoRow('Fecha de creación', dateFormat.format(_quote!.createdAt)),
                  _buildInfoRow('Válido hasta', dateFormat.format(_quote!.validUntil)),
                  _buildInfoRow('Creado por', _quote!.createdBy.name),
                  if (_quote!.notes != null && _quote!.notes!.isNotEmpty)
                    _buildInfoRow('Notas', _quote!.notes!),
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
                    'Detalles del Presupuesto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _quote!.items.length,
                    itemBuilder: (context, index) {
                      final item = _quote!.items[index];
                      return ListTile(
                        title: Text(item.description),
                        subtitle: Text(
                          item.isLabor ? 'Mano de obra' : 'Repuesto',
                          style: TextStyle(
                            color: item.isLabor ? Colors.blue : Colors.green,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          '${item.quantity} x ${currencyFormat.format(item.price)} = ${currencyFormat.format(item.total)}',
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  _buildPriceRow('Subtotal', currencyFormat.format(_quote!.subtotal)),
                  if (_quote!.discount != null && _quote!.discount! > 0)
                    _buildPriceRow(
                      'Descuento (${_quote!.discount}%)',
                      '- ${currencyFormat.format(_quote!.discountAmount)}',
                    ),
                  if (_quote!.tax != null && _quote!.tax! > 0)
                    _buildPriceRow(
                      'Impuestos (${_quote!.tax}%)',
                      '+ ${currencyFormat.format(_quote!.taxAmount)}',
                    ),
                  const Divider(),
                  _buildPriceRow(
                    'Total',
                    currencyFormat.format(_quote!.total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_quote!.status == QuoteStatus.pending)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const Text(
                      'Actualizar estado del presupuesto:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Aprobar'),
                          onPressed: () => _updateQuoteStatus(QuoteStatus.approved),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Rechazar'),
                          onPressed: () => _updateQuoteStatus(QuoteStatus.rejected),
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
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
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
  
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Está seguro de que desea eliminar este presupuesto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteQuote();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuote() async {
    if (_quote == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _quoteService.deleteQuote(_quote!.id);
      _showSuccessSnackBar('Presupuesto eliminado correctamente');
      Navigator.of(context).pop(true); // Volver a la pantalla anterior con resultado exitoso
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al eliminar el presupuesto: ${e.toString()}');
    }
  } // End of _QuoteDetailScreenState class
}
