import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  final ApiService apiService;
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
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
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No logs available.'));
          }

          final logs = snapshot.data!;
          // Using reversed display assuming oldest logs come first from API
          // Depending on API, you may not need to reverse
          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  logs[index],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.0,
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
