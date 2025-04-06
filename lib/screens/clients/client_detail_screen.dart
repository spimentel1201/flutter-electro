import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/customer.dart';
import 'package:electro_workshop/services/customer_service.dart';
import 'package:electro_workshop/screens/clients/client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final int customerId;

  const ClientDetailScreen({super.key, required this.customerId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> with SingleTickerProviderStateMixin {
  final CustomerService _customerService = GetIt.instance<CustomerService>();
  late TabController _tabController;
  Customer? _customer;
  List<Map<String, dynamic>> _repairHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customer = await _customerService.getCustomerById(widget.customerId);
      setState(() {
        _customer = customer;
        _isLoading = false;
      });
      _loadRepairHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar los datos del cliente: ${e.toString()}');
    }
  }

  Future<void> _loadRepairHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final history = await _customerService.getCustomerRepairHistory(widget.customerId);
      setState(() {
        _repairHistory = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      _showErrorSnackBar('Error al cargar el historial de reparaciones: ${e.toString()}');
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

  Future<void> _sendNotification(String repairId, String status) async {
    // This would be implemented with a proper notification service
    // For now, we'll just show a success message
    _showSuccessSnackBar('Notificación enviada al cliente sobre el estado de la reparación');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cliente'),
        actions: [
          if (_customer != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ClientFormScreen(
                      isEditing: true,
                      customer: _customer,
                    ),
                  ),
                ).then((_) => _loadCustomerData());
              },
              tooltip: 'Editar Cliente',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'INFORMACIÓN'),
            Tab(text: 'HISTORIAL'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? const Center(child: Text('Cliente no encontrado'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCustomerInfoTab(),
                    _buildRepairHistoryTab(),
                  ],
                ),
    );
  }

  Widget _buildCustomerInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerHeader(),
          const SizedBox(height: 24),
          _buildInfoSection('Información de Contacto', [
            _buildInfoItem(Icons.phone, 'Teléfono', _customer!.phone),
            _buildInfoItem(Icons.email, 'Email', _customer!.email),
            if (_customer!.address != null && _customer!.address!.isNotEmpty)
              _buildInfoItem(Icons.location_on, 'Dirección', _customer!.address!),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Información de Documento', [
            if (_customer!.documentType != null && _customer!.documentNumber != null)
              _buildInfoItem(Icons.badge, _customer!.documentType!, _customer!.documentNumber!),
          ]),
          if (_customer!.notes != null && _customer!.notes!.isNotEmpty) ...[  
            const SizedBox(height: 16),
            _buildInfoSection('Notas', [
              _buildInfoItem(Icons.note, '', _customer!.notes!),
            ]),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blue,
          child: Text(
            _customer!.name.isNotEmpty ? _customer!.name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 36, color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _customer!.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Cliente desde ${_formatDate(_customer!.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty) ...[  
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.phone,
          label: 'Llamar',
          onTap: () {
            // Implement call functionality
          },
        ),
        _buildActionButton(
          icon: Icons.email,
          label: 'Email',
          onTap: () {
            // Implement email functionality
          },
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'SMS',
          onTap: () {
            // Implement SMS functionality
          },
        ),
        _buildActionButton(
          icon: Icons.notifications,
          label: 'Notificar',
          onTap: () {
            _showNotificationDialog();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              radius: 20,
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairHistoryTab() {
    return _isLoadingHistory
        ? const Center(child: CircularProgressIndicator())
        : _repairHistory.isEmpty
            ? const Center(child: Text('No hay historial de reparaciones'))
            : ListView.builder(
                itemCount: _repairHistory.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final repair = _repairHistory[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      title: Text(
                        'Orden #${repair['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha: ${_formatDate(DateTime.fromMillisecondsSinceEpoch(repair['createdAt']))}'),
                          Text(
                            'Estado: ${repair['status']}',
                            style: TextStyle(
                              color: _getStatusColor(repair['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dispositivo: ${repair['deviceName']}'),
                              Text('Problema: ${repair['problem']}'),
                              Text('Diagnóstico: ${repair['diagnosis'] ?? 'Pendiente'}'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.notifications),
                                    label: const Text('Notificar Estado'),
                                    onPressed: () => _sendNotification(
                                      repair['id'].toString(),
                                      repair['status'],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Notificación'),
        content: const Text(
          'Seleccione el tipo de notificación que desea enviar al cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Notificación enviada al cliente');
            },
            child: const Text('ENVIAR'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'en progreso':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}