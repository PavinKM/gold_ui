import 'dart:convert';
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

  // 🎨 Color based on log type
  Color _getLogColor(String log) {
    if (log.contains('ERROR')) return Colors.red;
    if (log.contains('WARNING')) return Colors.orange;
    if (log.contains('START')) return Colors.green;
    if (log.contains('INFO')) return Colors.blue;
    return Colors.white;
  }

  // 🔥 Convert raw logs → clean logs
  List<String> _formatLogs(List<String> rawLogs) {
    List<String> formattedLogs = [];

    for (var raw in rawLogs) {
      try {
        final decoded = raw.contains('{')
            ? Map<String, dynamic>.from(jsonDecode(raw))
            : null;

        if (decoded != null && decoded['lines'] != null) {
          List lines = decoded['lines'];
          formattedLogs.addAll(lines.map((e) => e.toString()));
        } else {
          formattedLogs.add(raw);
        }
      } catch (e) {
        formattedLogs.add(raw); // fallback
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
          } 
          
          else if (snapshot.hasError) {
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
          } 
          
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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


// import 'package:flutter/material.dart';
// import '../services/api_service.dart';

// class LogsScreen extends StatefulWidget {
//   final ApiService apiService;
  
//   const LogsScreen({super.key, required this.apiService});

//   @override
//   State<LogsScreen> createState() => _LogsScreenState();
// }

// class _LogsScreenState extends State<LogsScreen> {
//   late Future<List<String>> _logsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _fetchLogs();
//   }

//   void _fetchLogs() {
//     setState(() {
//       _logsFuture = widget.apiService.getLogs();
//     });
//   }

//   Widget _formatLog(String log) {
//     String message = log;
//     String time = "";
//     String user = "";

//     IconData icon = Icons.info;
//     Color color = Colors.blue;
//     String label = "INFO";

//     final lower = log.toLowerCase();

//     if (lower.contains("error")) {
//       icon = Icons.error;
//       color = Colors.red;
//       label = "ERROR";
//     } else if (lower.contains("start")) {
//       icon = Icons.play_circle;
//       color = Colors.green;
//       label = "STARTED";
//     } else if (lower.contains("stop")) {
//       icon = Icons.stop_circle;
//       color = Colors.grey;
//       label = "STOPPED";
//     }

//     // Try extract time (basic)
//     try {
//       time = log.split(" ").first;
//     } catch (_) {}

//     // Try extract user
//     if (log.contains("user=")) {
//       try {
//         user = log.split("user=").last.split(" ").first;
//       } catch (_) {}
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: color),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: color,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),

//         Text(
//           message,
//           style: const TextStyle(fontSize: 13),
//         ),

//         const SizedBox(height: 6),

//         Row(
//           children: [
//             if (user.isNotEmpty)
//               Text("👤 $user  ", style: const TextStyle(fontSize: 11)),

//             if (time.isNotEmpty)
//               Text("🕒 $time",
//                   style: const TextStyle(fontSize: 11, color: Colors.grey)),
//           ],
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('System Logs'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchLogs,
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<String>>(
//         future: _logsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 60),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Failed to load logs\n${snapshot.error}',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.red),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _fetchLogs,
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No logs available.'));
//           }

//           final logs = snapshot.data!.reversed.toList();
//           return ListView.separated(
//             padding: const EdgeInsets.all(8.0),
//             itemCount: logs.length,
//             separatorBuilder: (context, index) => const Divider(height: 1),
//             // itemBuilder: (context, index) {
//             //   return Padding(
//             //     padding: const EdgeInsets.symmetric(vertical: 4.0),
//             //     child: Text(
//             //       logs[index],
//             //       style: const TextStyle(
//             //         fontFamily: 'monospace',
//             //         fontSize: 12.0,
//             //       ),
//             //     ),
//             //   );
//             // },
//             itemBuilder: (context, index) {
//               final log = logs[index];

//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: _formatLog(log),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
