import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/models/repair_order.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/screens/quotes/quote_form_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_detail_screen.dart';
import 'package:intl/intl.dart';

class RepairOrderQuotesScreen extends StatefulWidget {
  final String repairOrderId;
  final RepairOrder? repairOrder;

  const RepairOrderQuotesScreen({
    Key? key,
    required this.repairOrderId,
    this.repairOrder,
  }) : super(key: key);

  @override
  _RepairOrderQuotesScreenState createState() => _RepairOrderQuotesScreenState();
}

class _RepairOrderQuotesScreenState extends State<RepairOrderQuotesScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  List<Quote> _quotes = [];
  bool _isLoading = true;

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
      final quotes = await _quoteService.getQuotesByRepairOrder(widget.repairOrderId);
      setState(() {
        _quotes = quotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load quotes: ${e.toString()}');
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
        title: Text('Quotes for Order #${widget.repairOrderId.substring(0, 8)}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? _buildEmptyState()
              : _buildQuotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuoteFormScreen(
                repairOrderId: widget.repairOrderId,
              ),
            ),
          ).then((_) => _loadQuotes());
        },
        tooltip: 'Create Quote',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No quotes found for this repair order',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Quote'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuoteFormScreen(
                    repairOrderId: widget.repairOrderId,
                  ),
                ),
              ).then((_) => _loadQuotes());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesList() {
    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quotes.length,
        itemBuilder: (context, index) {
          final quote = _quotes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuoteDetailScreen(quoteId: quote.id),
                  ),
                ).then((_) => _loadQuotes());
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quote #${quote.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusChip(quote.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (quote.technician != null)
                      Text(
                        'Technician: ${quote.technician!.firstName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: \$${quote.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${DateFormat('MMM dd, yyyy').format(quote.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Items: ${quote.items.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case QuoteStatus.APPROVED:
        chipColor = Colors.green;
        break;
      case QuoteStatus.REJECTED:
        chipColor = Colors.red;
        break;
      case QuoteStatus.EXPIRED:
        chipColor = Colors.grey;
        break;
      case QuoteStatus.PENDING:
      default:
        chipColor = Colors.orange;
        break;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}