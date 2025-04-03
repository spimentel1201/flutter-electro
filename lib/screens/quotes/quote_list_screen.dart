import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/screens/quotes/quote_detail_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_form_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  List<Quote> _quotes = [];
  List<Quote> _filteredQuotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  QuoteStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotes = await _quoteService.getAllQuotes();
      setState(() {
        _quotes = quotes;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar los presupuestos: ${e.toString()}');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredQuotes = _quotes.where((quote) {
        // Aplicar filtro de búsqueda
        final matchesSearch = _searchQuery.isEmpty ||
            quote.repairOrder.customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            quote.repairOrder.deviceType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            quote.repairOrder.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            quote.repairOrder.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            quote.id.toString().contains(_searchQuery);

        // Aplicar filtro de estado
        final matchesStatus = _statusFilter == null || quote.status == _statusFilter;

        return matchesSearch && matchesStatus;
      }).toList();

      // Ordenar por fecha de creación (más reciente primero)
      _filteredQuotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar presupuestos',
                hintText: 'Nombre del cliente, dispositivo, marca, modelo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text('Filtro: '),
                  Chip(
                    label: Text(_getStatusText(_statusFilter!)),
                    backgroundColor: _getStatusColor(_statusFilter!).withOpacity(0.2),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _statusFilter = null;
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? const Center(child: Text('No se encontraron presupuestos'))
                    : ListView.builder(
                        itemCount: _filteredQuotes.length,
                        itemBuilder: (context, index) {
                          final quote = _filteredQuotes[index];
                          final dateFormat = DateFormat('dd/MM/yyyy');
                          final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '€');
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                'Presupuesto #${quote.id} - ${quote.repairOrder.customer.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${quote.repairOrder.deviceType} - ${quote.repairOrder.brand} ${quote.repairOrder.model}',
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Creado: ${dateFormat.format(quote.createdAt)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total: ${currencyFormat.format(quote.total)}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(quote.status),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _getStatusText(quote.status),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                    onPressed: () {
                                      _navigateToQuoteDetail(quote.id);
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                _navigateToQuoteDetail(quote.id);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToQuoteForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _navigateToQuoteDetail(int quoteId) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuoteDetailScreen(quoteId: quoteId),
      ),
    );

    if (result == true) {
      _loadQuotes();
    }
  }

  Future<void> _navigateToQuoteForm() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuoteFormScreen(),
      ),
    );

    if (result == true) {
      _loadQuotes();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              leading: Radio<QuoteStatus?>(
                value: null,
                groupValue: _statusFilter,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  setState(() {
                    _statusFilter = value;
                  });
                  _applyFilters();
                },
              ),
            ),
            ...QuoteStatus.values.map((status) => ListTile(
                  title: Text(_getStatusText(status)),
                  leading: Radio<QuoteStatus?>(
                    value: status,
                    groupValue: _statusFilter,
                    onChanged: (value) {
                      Navigator.of(context).pop();
                      setState(() {
                        _statusFilter = value;
                      });
                      _applyFilters();
                    },
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}