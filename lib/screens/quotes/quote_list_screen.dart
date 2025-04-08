import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/screens/quotes/quote_form_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_detail_screen.dart';
import 'package:intl/intl.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  List<Quote> _quotes = [];
  List<Quote> _filteredQuotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', QuoteStatus.PENDING, QuoteStatus.APPROVED, QuoteStatus.REJECTED, QuoteStatus.EXPIRED];
  
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
      _showErrorSnackBar('Failed to load quotes: ${e.toString()}');
    }
  }

  void _applyFilters() {
    var filtered = _quotes;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((quote) {
        return quote.customer?.name.toLowerCase().contains(query) ?? false ||
               quote.id.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply status filter
    if (_selectedStatus != 'All') {
      filtered = filtered.where((quote) => 
        quote.status == _selectedStatus
      ).toList();
    }
    
    setState(() {
      _filteredQuotes = filtered;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? const Center(child: Text('No quotes found'))
                    : _buildQuoteList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const QuoteFormScreen(),
            ),
          ).then((_) => _loadQuotes());
        },
        tooltip: 'Create Quote',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.05),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search quotes...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = status;
                          _applyFilters();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuotes.length,
      itemBuilder: (context, index) {
        final quote = _filteredQuotes[index];
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
                  if (quote.customer != null)
                    Text(
                      'Customer: ${quote.customer!.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
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