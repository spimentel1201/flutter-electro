import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/services/repair_service.dart';
import 'package:electro_workshop/screens/repairs/repair_detail_screen.dart';
import 'package:electro_workshop/screens/repairs/repair_form_screen.dart';

class RepairListScreen extends StatefulWidget {
  const RepairListScreen({super.key});

  @override
  State<RepairListScreen> createState() => _RepairListScreenState();
}

class _RepairListScreenState extends State<RepairListScreen> {
  final RepairService _repairService = GetIt.instance.get<RepairService>();
  List<RepairOrder>? _repairs;
  bool _isLoading = true;
  String? _errorMessage;
  final dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  Future<void> _loadRepairs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final repairs = await _repairService.getAllRepairOrders();
      
      setState(() {
        _repairs = repairs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar las órdenes de reparación: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de Reparación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRepairs,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RepairFormScreen(),
            ),
          );
          
          if (result == true) {
            _loadRepairs();
          }
        },
        child: const Icon(Icons.add),
      ),
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
              onPressed: _loadRepairs,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_repairs == null || _repairs!.isEmpty) {
      return const Center(
        child: Text(
          'No hay órdenes de reparación disponibles',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _repairs!.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final repair = _repairs![index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(repair.status as RepairOrderStatus),
              child: Icon(
                _getStatusIcon(repair.status as RepairOrderStatus),
                color: Colors.white,
              ),
            ),
            title: Text(
              '${repair.customer?.name ?? 'Cliente sin nombre'} - ${repair.items.isNotEmpty ? repair.items.first.brand : 'N/A'} ${repair.items.isNotEmpty ? repair.items.first.model : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${repair.id}'),
                Text('Fecha: ${dateFormat.format(repair.createdAt)}'),
                Text('Estado: ${_getStatusText(repair.status as RepairOrderStatus)}'),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RepairDetailScreen(repairId: repair.id),
                ),
              );
              
              if (result == true) {
                _loadRepairs();
              }
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(RepairOrderStatus status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return Colors.orange;
      case RepairOrderStatus.IN_PROGRESS:
        return Colors.blue;
      case RepairOrderStatus.WAITING_FOR_PARTS:
        return Colors.yellow;
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

  IconData _getStatusIcon(RepairOrderStatus status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return Icons.hourglass_empty;
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

  String _getStatusText(RepairOrderStatus status) {
    switch (status) {
      case RepairOrderStatus.RECEIVED:
        return 'Recibido';
      case RepairOrderStatus.IN_PROGRESS:
        return 'En progreso';
      case RepairOrderStatus.WAITING_FOR_PARTS:
        return 'Esperando piezas';
      case RepairOrderStatus.COMPLETED:
        return 'Completada';
      case RepairOrderStatus.DELIVERED:
        return 'Entregada';
      case RepairOrderStatus.CANCELLED:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }
}