import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PositionsScreen extends StatefulWidget {
  final AdminApi apiService;

  const PositionsScreen({super.key, required this.apiService});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _positionData;

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  Future<void> _fetchPositions() async {
    setState(() => _isLoading = true);

    try {
      final data = await widget.apiService.getPositions();
      debugPrint('POSITIONS RESPONSE: $data');
      setState(() {
        _positionData = data;
      });
    } catch (error) {
      debugPrint('ERROR FETCHING POSITIONS: $error');
      setState(() {
        _positionData = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getPnLColor(double pnl) {
    if (pnl > 0) return Colors.green;
    if (pnl < 0) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final hasPosition = _positionData?['has_open_position'] == true;
    final position = _positionData?['position'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        actions: [
          IconButton(
            onPressed: _fetchPositions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPositions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !hasPosition || position == null
            ? const Center(
                child: Text(
                  'No Open Positions',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildPositionCard(
                    Map<String, dynamic>.from(position as Map),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> pos) {
    final symbol = pos['tradingsymbol']?.toString() ?? 'N/A';
    final qty = pos['quantity'] as int? ?? 0;
    final pnl = (pos['pnl'] as num? ?? 0).toDouble();
    final avgPrice = (pos['average_price'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Qty: $qty', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Avg Price: ₹$avgPrice',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            'P&L: ₹${pnl.toStringAsFixed(2)}',
            style: TextStyle(
              color: _getPnLColor(pnl),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
