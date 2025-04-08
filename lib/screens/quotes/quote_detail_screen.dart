import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/models/quote.dart';
import 'package:electro_workshop/services/quote_service.dart';
import 'package:electro_workshop/screens/quotes/quote_form_screen.dart';
import 'package:intl/intl.dart';

class QuoteDetailScreen extends StatefulWidget {
  final String quoteId;

  const QuoteDetailScreen({Key? key, required this.quoteId}) : super(key: key);

  @override
  _QuoteDetailScreenState createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final QuoteService _quoteService = GetIt.instance<QuoteService>();
  Quote? _quote;
  bool _isLoading = true;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _loadQuoteDetails();
  }
  
  Future<void> _loadQuoteDetails() async {
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
      _showErrorSnackBar('Failed to load quote details: ${e.toString()}');
    }
  }

  Future<void> _refreshQuoteDetails() async {
    await _loadQuoteDetails();
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

  Future<void> _updateQuoteStatus(String status) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      await _quoteService.updateQuoteStatus(_quote!.id, status);
      _showSuccessSnackBar('Quote status updated successfully');
      _refreshQuoteDetails();
    } catch (e) {
      _showErrorSnackBar('Failed to update quote status: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _convertToSale() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      await _quoteService.convertToSale(_quote!.id);
      _showSuccessSnackBar('Quote converted to sale successfully');
      _refreshQuoteDetails();
    } catch (e) {
      _showErrorSnackBar('Failed to convert quote to sale: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quote == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quote Details'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Quote not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quote #${_quote!.id.substring(0, 8)}'),
        actions: [
          if (_quote!.status == QuoteStatus.PENDING)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditQuote(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshQuoteDetails,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16.0),
                        if (_quote!.customer != null) _buildCustomerInfoCard(),
                        const SizedBox(height: 16.0),
                        _buildQuoteDetailsCard(),
                        const SizedBox(height: 16.0),
                        _buildItemsCard(),
                        const SizedBox(height: 80.0), // Space for bottom buttons
                      ],
                    ),
                  ),
                  if (_quote!.status == QuoteStatus.PENDING)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildActionButtons(),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatusCard() {
    Color statusColor;
    switch (_quote!.status) {
      case QuoteStatus.APPROVED:
        statusColor = Colors.green;
        break;
      case QuoteStatus.REJECTED:
        statusColor = Colors.red;
        break;
      case QuoteStatus.EXPIRED:
        statusColor = Colors.grey;
        break;
      case QuoteStatus.PENDING:
      default:
        statusColor = Colors.orange;
        break;
    }

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _quote!.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(_quote!.createdAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated: ${DateFormat('MMM dd, yyyy').format(_quote!.updatedAt)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Name', _quote!.customer!.name),
            _buildInfoRow('Phone', _quote!.customer!.phone),
            if (_quote!.customer!.email != null && _quote!.customer!.email!.isNotEmpty)
              _buildInfoRow('Email', _quote!.customer!.email!),
            if (_quote!.customer!.address != null && _quote!.customer!.address!.isNotEmpty)
              _buildInfoRow('Address', _quote!.customer!.address!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuoteDetailsCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quote Details',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('Quote ID', _quote!.id),
            _buildInfoRow('Repair Order ID', _quote!.repairOrderId),
            if (_quote!.technician != null)
              _buildInfoRow('Technician', _quote!.technician!.firstName),
            _buildInfoRow('Total Amount', '\$${_quote!.totalAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quote!.items.length,
              itemBuilder: (context, index) {
                final item = _quote!.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              item.isLabor ? 'Labor' : 'Part',
                              style: TextStyle(
                                color: item.isLabor ? Colors.blue : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${item.price.toStringAsFixed(2)}'),
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${_quote!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _updateQuoteStatus(QuoteStatus.APPROVED),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Approve'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _updateQuoteStatus(QuoteStatus.REJECTED),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _convertToSale,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Convert to Sale'),
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToEditQuote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteFormScreen(quote: _quote),
      ),
    );
    
    if (result == true) {
      _refreshQuoteDetails();
    }
  }
}
