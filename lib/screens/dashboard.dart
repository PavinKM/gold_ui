import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'webview_login.dart';
import 'logs_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  const DashboardScreen({super.key, required this.apiService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isTokenValid = false;
  bool _isLoadingToken = true;

  String _engineStatus = 'Unknown';
  bool _isLoadingEngineStatus = true;
  bool _isEngineActionRunning = false;

  @override
  void initState() {
    super.initState();
    _fetchTokenStatus();
    _fetchEngineStatus();
  }

  Future<void> _fetchTokenStatus() async {
    setState(() => _isLoadingToken = true);
    try {
      final response = await widget.apiService.getTokenStatus();
      setState(() {
        _isTokenValid = response['valid'] ?? false;
      });
    } catch (e) {
      setState(() => _isTokenValid = false);
    } finally {
      setState(() => _isLoadingToken = false);
    }
  }

  Future<void> _fetchEngineStatus() async {
    setState(() => _isLoadingEngineStatus = true);
    try {
      final response = await widget.apiService.getEngineStatus();
      setState(() {
        _engineStatus = response['status'] ?? 'Stopped';
      });
    } catch (e) {
      setState(() => _engineStatus = 'Error');
    } finally {
      setState(() => _isLoadingEngineStatus = false);
    }
  }

  Future<void> _performEngineAction(Future<void> Function() action, String successMsg) async {
    if (_isEngineActionRunning) return;
    
    setState(() => _isEngineActionRunning = true);
    
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
      await _fetchEngineStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isEngineActionRunning = false);
    }
  }

  void _navigateToLogin() async {
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebviewLoginScreen(apiService: widget.apiService),
      ),
    );
    if (success == true) {
      _fetchTokenStatus();
      _fetchEngineStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchTokenStatus();
              _fetchEngineStatus();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTokenSection(),
            const SizedBox(height: 24),
            _buildEngineSection(),
            const SizedBox(height: 24),
            _buildLogsButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Zerodha Token Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _isLoadingToken
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isTokenValid ? Icons.check_circle : Icons.error,
                        color: _isTokenValid ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTokenValid ? 'Active' : 'Expired/Invalid',
                        style: TextStyle(
                          color: _isTokenValid ? Colors.green : Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _navigateToLogin,
              icon: const Icon(Icons.security),
              label: const Text('Update Token'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineSection() {
    final isRunning = _engineStatus.toLowerCase() == 'running';
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Trading Engine Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _isLoadingEngineStatus
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRunning ? Icons.play_circle_fill : Icons.stop_circle,
                        color: isRunning ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _engineStatus.toUpperCase(),
                        style: TextStyle(
                          color: isRunning ? Colors.green : Colors.grey[700],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              alignment: WrapAlignment.center,
              children: [
                _buildActionButton(
                  'Start Engine',
                  Icons.play_arrow,
                  Colors.green,
                  () => _performEngineAction(widget.apiService.startEngine, 'Engine Started'),
                  disabled: isRunning || _isEngineActionRunning,
                ),
                _buildActionButton(
                  'Stop Engine',
                  Icons.stop,
                  Colors.red,
                  () => _performEngineAction(widget.apiService.stopEngine, 'Engine Stopped'),
                  disabled: !isRunning || _isEngineActionRunning,
                ),
                _buildActionButton(
                  'Restart Engine',
                  Icons.refresh,
                  Colors.orange,
                  () => _performEngineAction(widget.apiService.restartEngine, 'Engine Restarted'),
                  disabled: _isEngineActionRunning,
                ),
              ],
            ),
            if (_isEngineActionRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed, {bool disabled = false}) {
    return ElevatedButton.icon(
      onPressed: disabled ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildLogsButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LogsScreen(apiService: widget.apiService),
          ),
        );
      },
      icon: const Icon(Icons.receipt_long),
      label: const Text('View Logs'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }
}
