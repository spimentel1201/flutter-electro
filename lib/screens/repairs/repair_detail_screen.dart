import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/services/repair_service.dart';
import 'package:electro_workshop/screens/repairs/repair_form_screen.dart';

class RepairDetailScreen extends StatefulWidget {
  final String repairId;

  const RepairDetailScreen({super.key, required this.repairId});

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  final RepairService _repairService = GetIt.instance.get<RepairService>();
  RepairOrder? _repair;
  bool _isLoading = true;
  String? _errorMessage;
  final dateFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  @override
  void initState() {
    super.initState();
    _loadRepair();
  }

  Future<void> _loadRepair() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repair = await _repairService.getRepairOrderById(widget.repairId);
      
      setState(() {
        _repair = repair;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar la orden de reparación: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _repairService.updateRepairOrderStatus(widget.repairId, newStatus);
      _loadRepair();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a ${_getStatusText(newStatus)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el estado: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${widget.repairId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRepair,
          ),
          if (_repair != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RepairFormScreen(repairId: widget.repairId),
                  ),
                );
                
                if (result == true) {
                  _loadRepair();
                }
              },
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _repair != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRepair,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_repair == null) {
      return const Center(
        child: Text('No se encontró la orden de reparación'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildCustomerCard(),
          const SizedBox(height: 16),
          _buildDevicesCard(),
          const SizedBox(height: 16),
          _buildDetailsCard(),
          const SizedBox(height: 16),
          _buildCostsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(_repair!.status),
                  child: Icon(
                    _getStatusIcon(_repair!.status),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado: ${_getStatusText(_repair!.status)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Última actualización: ${dateFormat.format(_repair!.updatedAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de inicio'),
                      Text(
                        dateFormat.format(_repair!.startDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de finalización'),
                      Text(
                        _repair!.endDate != null
                            ? dateFormat.format(_repair!.endDate!)
                            : 'Pendiente',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_repair!.customer != null) ...[
              _buildInfoRow('Nombre', _repair!.customer!.name),
              _buildInfoRow('Teléfono', _repair!.customer!.phone),
              _buildInfoRow('Email', _repair!.customer!.email ?? 'N/A'),
              _buildInfoRow('Dirección', _repair!.customer!.address ?? 'N/A'),
            ] else
              const Text('Información del cliente no disponible'),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dispositivos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_repair!.items.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _repair!.items.length,
                itemBuilder: (context, index) {
                  final device = _repair!.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispositivo ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Tipo', device.deviceType ?? 'N/A'),
                          _buildInfoRow('Marca', device.brand ?? 'N/A'),
                          _buildInfoRow('Modelo', device.model ?? 'N/A'),
                          _buildInfoRow('Nº Serie', device.serialNumber ?? 'N/A'),
                          if (device.problemDescription != null && device.problemDescription.isNotEmpty)
                            _buildInfoRow('Problema', device.problemDescription!),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              const Text('No hay dispositivos registrados'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalles de la Reparación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Descripción', _repair!.description),
            if (_repair!.notes != null && _repair!.notes!.isNotEmpty)
              _buildInfoRow('Notas', _repair!.notes!),
            if (_repair!.technician != null)
              _buildInfoRow('Técnico', _repair!.technician!.firstName),
          ],
        ),
      ),
    );
  }

  Widget _buildCostsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Costos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Revisión inicial',
              currencyFormat.format(_repair!.initialReviewCost),
            ),
            _buildInfoRow(
              'Costo total',
              currencyFormat.format(_repair!.totalCost),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusButton(),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implementar generación de presupuesto
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generando presupuesto...')),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Generar Presupuesto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton() {
    return Expanded(
      child: PopupMenuButton<String>(
        onSelected: _updateStatus,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: RepairOrderStatus.RECEIVED,
            child: Text('Recibido'),
          ),
          const PopupMenuItem<String>(
            value: RepairOrderStatus.DIAGNOSED,
            child: Text('Diagnosticado'),
          ),
          const PopupMenuItem<String>(
            value: RepairOrderStatus.IN_PROGRESS,
            child: Text('En progreso'),
          ),
          const PopupMenuItem<String>(
            value: RepairOrderStatus.WAITING_FOR_PARTS,
            child: Text('Esperando piezas'),
          ),
          const PopupMenuItem<String>(
            value: RepairOrderStatus.COMPLETED,
            child: Text('Completado'),
          ),
          const PopupMenuItem<String>(
            value: RepairOrderStatus.DELIVERED,
            child: Text('Entregado'),
          ),
          const PopupMenuItem<String>(
            value: RepairOrderStatus.CANCELLED,
            child: Text('Cancelado'),
          ),
        ],
        child: ElevatedButton.icon(
          onPressed: null, // El botón en sí no hace nada, solo el popup
          icon: const Icon(Icons.update),
          label: const Text('Cambiar Estado'),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return Colors.orange;
      case RepairOrderStatus.DIAGNOSED:
        return Colors.amber;
      case RepairOrderStatus.IN_PROGRESS:
        return Colors.blue;
      case RepairOrderStatus.WAITING_FOR_PARTS:
        return Colors.yellow.shade800;
      case RepairOrderStatus.COMPLETED:
        return Colors.green;
      case RepairOrderStatus.DELIVERED:
        return Colors.purple;
      case RepairOrderStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return Icons.inventory;
      case RepairOrderStatus.DIAGNOSED:
        return Icons.search;
      case RepairOrderStatus.IN_PROGRESS:
        return Icons.build;
      case RepairOrderStatus.WAITING_FOR_PARTS:
        return Icons.pending_actions;
      case RepairOrderStatus.COMPLETED:
        return Icons.check_circle;
      case RepairOrderStatus.DELIVERED:
        return Icons.delivery_dining;
      case RepairOrderStatus.CANCELLED:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return 'Recibido';
      case RepairOrderStatus.DIAGNOSED:
        return 'Diagnosticado';
      case RepairOrderStatus.IN_PROGRESS:
        return 'En progreso';
      case RepairOrderStatus.WAITING_FOR_PARTS:
        return 'Esperando piezas';
      case RepairOrderStatus.COMPLETED:
        return 'Completado';
      case RepairOrderStatus.DELIVERED:
        return 'Entregado';
      case RepairOrderStatus.CANCELLED:
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }
}