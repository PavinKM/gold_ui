import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  final AdminApi apiService;

  const LogsScreen({super.key, required this.apiService});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<String>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  void _fetchLogs() {
    setState(() {
      _logsFuture = widget.apiService.getLogs();
    });
  }

  Color _getLogColor(String log) {
    if (log.contains('ERROR')) return Colors.red;
    if (log.contains('WARNING')) return Colors.orange;
    if (log.contains('START')) return Colors.green;
    if (log.contains('INFO')) return Colors.blue;
    return Colors.white;
  }

  List<String> _formatLogs(List<String> rawLogs) {
    final formattedLogs = <String>[];

    for (final raw in rawLogs) {
      try {
        final decoded = raw.contains('{') ? jsonDecode(raw) : null;
        if (decoded is Map<String, dynamic> && decoded['lines'] is List) {
          formattedLogs.addAll(
            (decoded['lines'] as List).map((entry) => entry.toString()),
          );
        } else {
          formattedLogs.add(raw);
        }
      } catch (_) {
        formattedLogs.add(raw);
      }
    }

    return formattedLogs.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLogs),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load logs\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchLogs,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No logs available.'));
          }

          final logs = _formatLogs(snapshot.data!);

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final log = logs[index];

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: _getLogColor(log),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
