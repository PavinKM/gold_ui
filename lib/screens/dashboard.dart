import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'positions_screen.dart';
import 'engine_state_screen.dart';
import 'logs_screen.dart';
import 'webview_login.dart';

class DashboardScreen extends StatefulWidget {
  final AdminApi apiService;
  final Duration actionPollInterval;
  final Duration actionTimeout;

  const DashboardScreen({
    super.key,
    required this.apiService,
    this.actionPollInterval = const Duration(seconds: 2),
    this.actionTimeout = const Duration(seconds: 45),
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color bgCanvas = Color(0xFFF8FAFC);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  bool _isTokenValid = false;
  String? _userId;
  String _engineStatus = 'unknown';
  Map<String, dynamic>? _engineHealth;
  bool _isRefreshing = true;
  bool _isEngineActionRunning = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  bool get _engineHealthy => _engineHealth?['ok'] == true;

  bool get _isStopped =>
      <String>{'stopped', 'inactive', 'exited', 'dead'}.contains(_engineStatus);

  String get _effectiveEngineStatus {
    switch (_engineStatus) {
      case 'running':
        return _engineHealthy ? 'running' : 'degraded';
      case 'created':
      case 'starting':
        return 'starting';
      case 'restarting':
        return 'restarting';
      case 'inactive':
      case 'stopped':
      case 'exited':
      case 'dead':
        return 'stopped';
      case 'error':
        return 'error';
      default:
        return _engineStatus;
    }
  }

  Future<void> _fetchInitialData() async {
    if (mounted) {
      setState(() => _isRefreshing = true);
    }
    await _fetchDashboardSummary();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Map<String, dynamic>? _coerceMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Future<void> _fetchDashboardSummary() async {
    try {
      final summary = await widget.apiService.getDashboardSummary();
      final kite = _coerceMap(summary['kite']) ?? const <String, dynamic>{};
      final engine = _coerceMap(summary['engine']) ?? const <String, dynamic>{};
      final orders = _coerceMap(summary['orders']) ?? const <String, dynamic>{};
      if (!mounted) {
        return;
      }
      setState(() {
        _isTokenValid = kite['has_access_token'] == true;
        _userId = kite['user_id']?.toString();
        _engineStatus = (engine['status'] ?? 'unknown')
            .toString()
            .toLowerCase();
        _engineHealth = <String, dynamic>{
          'ok': engine['ok'],
          'mode': engine['mode'],
          'backend': engine['backend'],
          'service_name': engine['service_name'],
          'last_heartbeat': engine['last_heartbeat'],
          'heartbeat_age_sec': engine['heartbeat_age_sec'],
          'heartbeat_stale': engine['heartbeat_stale'],
          'heartbeat_stale_limit_sec': engine['heartbeat_stale_limit_sec'],
          'token_loaded': kite['has_access_token'],
          'open_position_exists': orders['open_position_exists'],
          'pending_entry_exists': orders['pending_entry_exists'],
          'pending_exit_exists': orders['pending_exit_exists'],
        };
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isTokenValid = false;
        _userId = null;
        _engineStatus = 'error';
        _engineHealth = <String, dynamic>{
          'ok': false,
          'error': error.toString(),
        };
      });
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _waitForEngineTransition(bool Function() isComplete) async {
    final deadline = DateTime.now().add(widget.actionTimeout);

    while (DateTime.now().isBefore(deadline)) {
      await _fetchDashboardSummary();
      if (isComplete()) {
        return;
      }
      await Future.delayed(widget.actionPollInterval);
    }

    throw TimeoutException(
      'Timed out while waiting for the engine to settle. '
      'Current state: ${_effectiveEngineStatus.toUpperCase()}',
    );
  }

  Future<void> _performEngineAction({
    required Future<Map<String, dynamic>> Function() action,
    required String successMsg,
    required bool Function() completionCheck,
    String? confirmTitle,
    String? confirmBody,
    String confirmLabel = 'Continue',
  }) async {
    if (_isEngineActionRunning) {
      return;
    }

    if (confirmTitle != null && confirmBody != null) {
      final confirmed = await _confirmAction(
        title: confirmTitle,
        body: confirmBody,
        confirmLabel: confirmLabel,
      );
      if (!confirmed) {
        return;
      }
    }

    setState(() => _isEngineActionRunning = true);

    try {
      await action();
      await _waitForEngineTransition(completionCheck);
      if (!mounted) {
        return;
      }
      _showSnackBar(successMsg, successGreen);
    } on TimeoutException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(error.message ?? error.toString(), warningAmber);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Action failed: $error', dangerRed);
    } finally {
      await _fetchInitialData();
      if (mounted) {
        setState(() => _isEngineActionRunning = false);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _openLogin() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => WebviewLoginScreen(apiService: widget.apiService),
      ),
    );
    if (result != null) {
      await _fetchInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = _effectiveEngineStatus;

    return Scaffold(
      backgroundColor: bgCanvas,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 25),
              _buildStatusGrid(effectiveStatus),
              const SizedBox(height: 30),
              _buildSectionTitle('System Connectivity'),
              const SizedBox(height: 12),
              _buildTokenCard(),
              const SizedBox(height: 30),
              _buildSectionTitle('Control Health'),
              const SizedBox(height: 12),
              _buildHealthStatusCard(effectiveStatus),
              const SizedBox(height: 16),
              _buildSectionTitle('Execution Controls'),
              const SizedBox(height: 12),
              _buildEngineControls(effectiveStatus),
              const SizedBox(height: 40),
              _buildPositionsButton(),
              const SizedBox(height: 12),
              _buildEngineStateButton(),
              const SizedBox(height: 12),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Staminal EGIS',
        style: TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      actions: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            onPressed: _fetchInitialData,
            icon: const Icon(Icons.sync_rounded, color: accentIndigo),
          ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOLD Admin',
          style: TextStyle(
            color: Colors.blueGrey[900],
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'User ID: ${_userId ?? 'Guest Session'}',
          style: TextStyle(
            color: Colors.blueGrey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGrid(String effectiveStatus) {
    return Row(
      children: [
        _buildQuickStat(
          'Broker Status',
          _isTokenValid ? 'CONNECTED' : 'DISCONNECTED',
          _isTokenValid ? successGreen : dangerRed,
          _isTokenValid ? Icons.lan : Icons.lan_outlined,
        ),
        const SizedBox(width: 16),
        _buildQuickStat(
          'Engine Mode',
          effectiveStatus.toUpperCase(),
          _statusColor(effectiveStatus),
          _statusIcon(effectiveStatus),
        ),
      ],
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.blueGrey[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zerodha API Access',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _isTokenValid
                      ? 'Broker token available for engine startup and restart.'
                      : 'Authentication required before starting or restarting the engine.',
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_isTokenValid ? 'Refresh' : 'Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(String effectiveStatus) {
    final heartbeatAge = (_engineHealth?['heartbeat_age_sec'] as num?)
        ?.toDouble();
    final lastHeartbeat = _engineHealth?['last_heartbeat']?.toString();
    final tokenLoaded = _engineHealth?['token_loaded'];
    final openPosition = _engineHealth?['open_position_exists'];
    final pendingEntry = _engineHealth?['pending_entry_exists'];
    final pendingExit = _engineHealth?['pending_exit_exists'];
    final heartbeatStale = _engineHealth?['heartbeat_stale'] == true;
    final backend = _engineHealth?['backend']?.toString();
    final serviceName = _engineHealth?['service_name']?.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Engine Health',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (_isEngineActionRunning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: _fetchInitialData,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Refresh'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(
                effectiveStatus.toUpperCase(),
                _statusColor(effectiveStatus),
              ),
              if (heartbeatAge != null)
                _statusChip(
                  'HB ${heartbeatAge.toStringAsFixed(0)}s',
                  accentIndigo,
                ),
              if (tokenLoaded != null)
                _statusChip(
                  tokenLoaded == true ? 'TOKEN LOADED' : 'TOKEN MISSING',
                  tokenLoaded == true ? successGreen : warningAmber,
                ),
              if (openPosition != null)
                _statusChip(
                  openPosition == true ? 'POSITION OPEN' : 'NO POSITION',
                  openPosition == true ? warningAmber : Colors.blueGrey,
                ),
              if (pendingEntry != null)
                _statusChip(
                  pendingEntry == true ? 'ENTRY PENDING' : 'NO PENDING ENTRY',
                  pendingEntry == true ? warningAmber : Colors.blueGrey,
                ),
              if (pendingExit != null)
                _statusChip(
                  pendingExit == true ? 'EXIT PENDING' : 'NO PENDING EXIT',
                  pendingExit == true ? warningAmber : Colors.blueGrey,
                ),
              if (heartbeatStale) _statusChip('HEARTBEAT STALE', dangerRed),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lastHeartbeat == null
                ? 'Heartbeat unavailable. The engine may still be warming up.'
                : 'Last heartbeat: $lastHeartbeat',
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
          ),
          if (backend != null || serviceName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Backend: ${backend ?? 'N/A'} | Service: ${serviceName ?? 'N/A'}',
              style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEngineControls(String effectiveStatus) {
    final canStart = !_isEngineActionRunning && _isTokenValid && _isStopped;
    final canStop =
        !_isEngineActionRunning && !_isStopped && _engineStatus != 'error';
    final canRestart =
        !_isEngineActionRunning &&
        _isTokenValid &&
        !_isStopped &&
        _engineStatus != 'error';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                'Current state: ${effectiveStatus.toUpperCase()}',
                style: TextStyle(
                  color: _statusColor(effectiveStatus),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Actions only succeed once the engine reaches the requested terminal state.',
            style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMainActionBtn(
                'START',
                Icons.play_arrow_rounded,
                successGreen,
                canStart
                    ? () => _performEngineAction(
                        action: widget.apiService.startEngine,
                        successMsg: 'Engine is running.',
                        completionCheck: () =>
                            _engineStatus == 'running' && _engineHealthy,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              _buildMainActionBtn(
                'STOP',
                Icons.stop_rounded,
                dangerRed,
                canStop
                    ? () => _performEngineAction(
                        action: widget.apiService.stopEngine,
                        successMsg: 'Engine has stopped.',
                        completionCheck: () => _isStopped,
                        confirmTitle: 'Stop engine?',
                        confirmBody:
                            'This stops the live engine immediately. Continue only if you expect order handling to halt.',
                        confirmLabel: 'Stop',
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMainActionBtn(
            'RESTART ENGINE',
            Icons.restart_alt_rounded,
            Colors.orange[700]!,
            canRestart
                ? () => _performEngineAction(
                    action: widget.apiService.restartEngine,
                    successMsg: 'Engine restart completed.',
                    completionCheck: () =>
                        _engineStatus == 'running' && _engineHealthy,
                    confirmTitle: 'Restart engine?',
                    confirmBody:
                        'This interrupts the engine and reconnects the data and broker sessions. Continue only if the engine needs recovery.',
                    confirmLabel: 'Restart',
                  )
                : null,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isFullWidth = false,
  }) {
    final isDisabled = onTap == null;
    final btn = Material(
      color: isDisabled ? Colors.grey[100] : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDisabled ? Colors.grey : color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return isFullWidth ? btn : Expanded(child: btn);
  }

  Widget _buildPositionsButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PositionsScreen(apiService: widget.apiService),
            ),
          );
        },
        icon: const Icon(Icons.show_chart),
        label: const Text('VIEW POSITIONS'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEngineStateButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EngineStateScreen(apiService: widget.apiService),
            ),
          );
        },
        icon: const Icon(Icons.analytics),
        label: const Text('VIEW ENGINE STATE'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LogsScreen(apiService: widget.apiService),
          ),
        ),
        icon: const Icon(Icons.article_outlined),
        label: const Text('EXAMINE SYSTEM LOGS'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.blueGrey[300],
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'running':
        return successGreen;
      case 'degraded':
        return warningAmber;
      case 'starting':
      case 'restarting':
        return accentIndigo;
      case 'stopped':
        return Colors.blueGrey;
      default:
        return dangerRed;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'running':
        return Icons.bolt;
      case 'degraded':
        return Icons.warning_amber_rounded;
      case 'starting':
      case 'restarting':
        return Icons.autorenew_rounded;
      case 'stopped':
        return Icons.power_settings_new;
      default:
        return Icons.error_outline;
    }
  }
}
