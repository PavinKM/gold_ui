import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class EngineStateScreen extends StatefulWidget {
  final AdminApi apiService;
  final Duration refreshInterval;

  const EngineStateScreen({
    super.key,
    required this.apiService,
    this.refreshInterval = const Duration(seconds: 10),
  });

  @override
  State<EngineStateScreen> createState() => _EngineStateScreenState();
}

class _EngineStateScreenState extends State<EngineStateScreen> {
  late Future<Map<String, dynamic>> _futureData;
  Timer? _timer;

  final Color _accentColor = const Color(0xFF6366F1);
  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _refreshData();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _refreshData());
  }

  void _refreshData() {
    setState(() {
      _futureData = widget.apiService.getEngineState();
    });
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bgDark,
        cardColor: _cardDark,
        appBarTheme: AppBarTheme(backgroundColor: _bgDark, elevation: 0),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: const [
              Text(
                'ENGINE STATE',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Live Strategy Telemetry',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final data = snapshot.data ?? const <String, dynamic>{};
            final stateAvailable = data['state_available'] == true;
            final symbol = data['symbol']?.toString() ?? 'N/A';
            final bias = _asMap(data['market_bias']);
            final setup = _asMap(data['active_setup']);
            final decision = _asMap(data['last_5m_decision']);
            final setupToast = data['setup_toast']?.toString();
            final structureToast = data['structure_toast']?.toString();
            final events = _asMapList(data['recent_setup_events']);

            return RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (setupToast != null) _buildToast(setupToast),
                    if (structureToast != null) _buildToast(structureToast),
                    _buildHeader(symbol, stateAvailable),
                    const SizedBox(height: 20),
                    _buildSectionTitle('DECISION'),
                    _buildDecisionCard(decision),
                    const SizedBox(height: 20),
                    _buildSectionTitle('MARKET BIAS'),
                    _buildBiasCard(bias),
                    const SizedBox(height: 20),
                    _buildSectionTitle('ACTIVE SETUP'),
                    _buildSetupCard(setup),
                    const SizedBox(height: 20),
                    _buildSectionTitle('RECENT EVENTS'),
                    _buildRecentEvents(events),
                    const SizedBox(height: 30),
                    Text(
                      'Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String symbol, bool stateAvailable) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentColor, _accentColor.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                symbol,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stateAvailable
                    ? 'Live setup snapshot available'
                    : 'Waiting for live setup data',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const Icon(Icons.sensors, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildToast(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic>? decision) {
    if (decision == null) {
      return _emptyCard('No recent 5-minute decision yet.');
    }

    final act = decision['decision']?.toString() ?? 'UNKNOWN';
    final color = _getDecisionColor(act);

    return _baseCard(
      child: Column(
        children: [
          Text(
            act,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(decision['reason']?.toString() ?? 'No reason supplied'),
        ],
      ),
    );
  }

  Color _getDecisionColor(String decision) {
    final value = decision.toUpperCase();
    if (value.contains('BUY')) {
      return Colors.green;
    }
    if (value.contains('SELL')) {
      return Colors.red;
    }
    if (value.contains('WAIT')) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  Widget _buildBiasCard(Map<String, dynamic>? bias) {
    if (bias == null) {
      return _emptyCard('Bias unavailable while the engine warms up.');
    }

    return _baseCard(
      child: Column(
        children: [
          _row('Trend', bias['trend']),
          _row('ATR', bias['atr']),
          _row('Strength', bias['trend_strength']),
          _row('Armed', bias['armed']),
          _row('Source', bias['source']),
        ],
      ),
    );
  }

  Widget _buildSetupCard(Map<String, dynamic>? setup) {
    if (setup == null) {
      return _emptyCard('No active setup right now.');
    }

    return Column(
      children: [
        _sectionCard('STATE INFO', [
          _row('State', setup['state']),
          _row('Bias', setup['bias']),
          _row('Regime', setup['regime']),
        ]),
        _sectionCard('PRICE LEVELS', [
          _row('Ref High', setup['ref_high']),
          _row('Ref Low', setup['ref_low']),
          _row('Pullback High', setup['pullback_high']),
          _row('Pullback Low', setup['pullback_low']),
          _row('Close', setup['close']),
        ]),
        _sectionCard('INDICATORS', [
          _row('VWAP', setup['vwap']),
          _row('ATR', setup['atr']),
          _row('Body Ratio', setup['body_ratio']),
          _row('Close Strength', setup['close_strength']),
        ]),
        _sectionCard('TIMING', [
          _row('Expiry (sec)', setup['expiry_remaining_sec']),
          _row('Last Update', setup['ts']),
        ]),
      ],
    );
  }

  Widget _buildRecentEvents(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return _emptyCard('No recent setup events recorded yet.');
    }

    return Column(
      children: events.map<Widget>((event) {
        return _baseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['EVENT']?.toString() ?? 'UNKNOWN EVENT',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${event['bias'] ?? 'N/A'} | ${event['regime'] ?? 'N/A'} | ${event['state'] ?? 'N/A'}',
              ),
              const SizedBox(height: 4),
              Text(
                event['ts']?.toString() ?? 'Timestamp unavailable',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _row(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(value?.toString() ?? 'N/A', textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _baseCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _emptyCard(String message) {
    return _baseCard(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}
