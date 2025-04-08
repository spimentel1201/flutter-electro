import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';

class QuoteShareScreen extends StatefulWidget {
  final String quoteId; // Changed from int to String

  const QuoteShareScreen({super.key, required this.quoteId});

  @override
  State<QuoteShareScreen> createState() => _QuoteShareScreenState();
}

class _QuoteShareScreenState extends State<QuoteShareScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  Quote? _quote;
  bool _isLoading = true;
  final _messageController = TextEditingController();
  bool _includeItemDetails = true;
  bool _includeTotal = true;
  bool _includeValidUntil = true;
  bool _includeCustomMessage = false;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _messageController.dispose();
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
        _initializeDefaultMessage();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar el presupuesto: ${e.toString()}');
    }
  }

  void _initializeDefaultMessage() {
    if (_quote == null) return;

    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');

    _messageController.text = 'Hola ${_quote!.customer?.name ?? "Cliente"}, '
        'le enviamos el presupuesto #${_quote!.id} para la reparación de su '
        'dispositivo. '
        'El total es de ${currencyFormat.format(_quote!.totalAmount)}. '
        'Por favor, responda para aprobar o rechazar el presupuesto.';
  }

  String _buildMessage() {
    if (_quote == null) return '';

    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final dateFormat = DateFormat('dd/MM/yyyy');

    String message = 'Hola ${_quote!.customer?.name ?? "Cliente"}, '
        'le enviamos el presupuesto #${_quote!.id} para la reparación de su '
        'dispositivo.';

    if (_includeItemDetails) {
      message += '\n\nDetalles del presupuesto:';
      for (var item in _quote!.items) {
        message += '\n- ${item.description}: ${item.quantity} x ${currencyFormat.format(item.price)} = ${currencyFormat.format(item.price * item.quantity)}';
      }
    }

    if (_includeTotal) {
      message += '\n\nTotal: ${currencyFormat.format(_quote!.totalAmount)}';
    }

    if (_includeCustomMessage && _messageController.text.isNotEmpty) {
      message += '\n\n${_messageController.text}';
    } else if (!_includeCustomMessage) {
      message += '\n\nPor favor, responda para aprobar o rechazar el presupuesto.';
    }

    return message;
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

  Future<void> _sendByEmail() async {
    if (_quote == null) return;

    try {
      // En una aplicación real, aquí enviaríamos el correo con el mensaje personalizado
      // Por ahora, usamos el método existente
      await _quoteService.sendQuoteToCustomer(
        _quote!.id,
        _quote!.customer?.email ?? '',
      );
      _showSuccessSnackBar('Presupuesto enviado por email correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al enviar el presupuesto por email: ${e.toString()}');
    }
  }

  Future<void> _sendByWhatsApp() async {
    if (_quote == null) return;

    final phone = _quote!.customer?.phone;
    final message = Uri.encodeComponent(_buildMessage());

    final whatsappUrl = 'https://wa.me/$phone?text=$message';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('No se pudo abrir WhatsApp');
    }
  }

  Future<void> _sendBySMS() async {
    if (_quote == null) return;

    final phone = _quote!.customer?.phone;
    final message = Uri.encodeComponent(_buildMessage());

    final smsUrl = 'sms:$phone?body=$message';

    if (await canLaunchUrl(Uri.parse(smsUrl))) {
      await launchUrl(Uri.parse(smsUrl));
    } else {
      _showErrorSnackBar('No se pudo abrir la aplicación de mensajes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compartir Presupuesto #${widget.quoteId}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quote == null
              ? const Center(child: Text('No se pudo cargar el presupuesto'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              _buildInfoRow('Nombre', _quote!.customer?.name ?? 'N/A'),
                              _buildInfoRow('Teléfono', _quote!.customer?.phone ?? 'N/A'),
                              _buildInfoRow('Email', _quote!.customer?.email ?? 'N/A'),
                              const Divider(),
                              Text(
                                'Información de Dispositivos',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              // Display multiple devices from repair order items
                              if (_quote!.repairOrder?.items != null && _quote!.repairOrder!.items.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _quote!.repairOrder!.items.length,
                                  itemBuilder: (context, index) {
                                    final device = _quote!.repairOrder!.items[index];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (index > 0) const Divider(height: 16),
                                        Text(
                                          'Dispositivo ${index + 1}:',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildInfoRow('Tipo', device.deviceType ?? 'N/A'),
                                        _buildInfoRow('Marca', device.brand ?? 'N/A'),
                                        _buildInfoRow('Modelo', device.model ?? 'N/A'),
                                      ],
                                    );
                                  },
                                )
                              else
                                const Text('No hay dispositivos disponibles'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Opciones de mensaje
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Opciones de Mensaje',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Incluir detalles de ítems'),
                                value: _includeItemDetails,
                                onChanged: (value) {
                                  setState(() {
                                    _includeItemDetails = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Incluir total'),
                                value: _includeTotal,
                                onChanged: (value) {
                                  setState(() {
                                    _includeTotal = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Incluir fecha de validez'),
                                value: _includeValidUntil,
                                onChanged: (value) {
                                  setState(() {
                                    _includeValidUntil = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Mensaje personalizado'),
                                value: _includeCustomMessage,
                                onChanged: (value) {
                                  setState(() {
                                    _includeCustomMessage = value;
                                  });
                                },
                              ),
                              if (_includeCustomMessage) ...[                                
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Mensaje personalizado',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vista previa del mensaje
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vista Previa del Mensaje',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_buildMessage()),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botones de envío
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.email),
                            label: const Text('Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _sendByEmail,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.message),
                            label: const Text('WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _sendByWhatsApp,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.sms),
                            label: const Text('SMS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _sendBySMS,
                          ),
                        ],
                      ),
                    ],
                  ),
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