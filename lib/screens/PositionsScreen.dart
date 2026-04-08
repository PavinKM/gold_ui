import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PositionsScreen extends StatefulWidget {
  final ApiService apiService;

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

      print("POSITIONS RESPONSE: $data");

      setState(() {
        _positionData = data;
      });

    } catch (e) {
      print("ERROR FETCHING POSITIONS: $e");

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
    final bool hasPosition =
        _positionData?['has_open_position'] == true;

    final position = _positionData?['position'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Positions"),
        actions: [
          IconButton(
            onPressed: _fetchPositions,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPositions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())

            // ❌ NO POSITION
            : !hasPosition || position == null
                ? const Center(
                    child: Text(
                      "No Open Positions",
                      style: TextStyle(fontSize: 16),
                    ),
                  )

                // ✅ POSITION EXISTS
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildPositionCard(position),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> pos) {
    final String symbol = pos['tradingsymbol'] ?? "N/A";
    final int qty = pos['quantity'] ?? 0;
    final double pnl = (pos['pnl'] ?? 0).toDouble();
    final double avgPrice =
        (pos['average_price'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SYMBOL + QTY
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
              Text(
                "Qty: $qty",
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // AVG PRICE
          Text(
            "Avg Price: ₹$avgPrice",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 10),

          // PNL
          Text(
            "P&L: ₹${pnl.toStringAsFixed(2)}",
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



// import 'package:flutter/material.dart';
// import '../services/api_service.dart';

// class PositionsScreen extends StatefulWidget {
//   final ApiService apiService;

//   const PositionsScreen({super.key, required this.apiService});

//   @override
//   State<PositionsScreen> createState() => _PositionsScreenState();
// }

// class _PositionsScreenState extends State<PositionsScreen> {
//   bool _isLoading = true;
//   // List<dynamic> _positions = [];
//   Map<String, dynamic>? _positionData;


//   @override
//   void initState() {
//     super.initState();
//     _fetchPositions();
//   }

//   // Future<void> _fetchPositions() async {
//   //   setState(() => _isLoading = true);

//   //   try {
//   //     final data = await widget.apiService.getPositions();

//   //     print("POSITIONS RESPONSE: $data");

//   //     setState(() {
//   //       _positions = data ?? [];
//   //     });
//   //   } catch (e) {
//   //     print("ERROR FETCHING POSITIONS: $e");
//   //     _positions = [];
//   //   } finally {
//   //     setState(() => _isLoading = false);
//   //   }
//   // }

//   Future<void> _fetchPositions() async {
//     setState(() => _isLoading = true);

//     try {
//       final data = await widget.apiService.getPositions();

//       print("POSITIONS RESPONSE: $data");

//       setState(() {
//         _positionData = data; // ✅ store full response
//       });

//     } catch (e) {
//       print("ERROR FETCHING POSITIONS: $e");

//       setState(() {
//         _positionData = null;
//       });

//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }


//   Color _getPnLColor(double pnl) {
//     if (pnl > 0) return Colors.green;
//     if (pnl < 0) return Colors.red;
//     return Colors.grey;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Positions"),
//         actions: [
//           IconButton(
//             onPressed: _fetchPositions,
//             icon: const Icon(Icons.refresh),
//           )
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _fetchPositions,
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _positions.isEmpty
//                 ? const Center(child: Text("No Positions Found"))
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: _positions.length,
//                     itemBuilder: (context, index) {
//                       final pos = _positions[index];

//                       final String symbol = pos['tradingsymbol'] ?? "N/A";
//                       final int qty = pos['quantity'] ?? 0;
//                       final double pnl =
//                           (pos['pnl'] ?? 0).toDouble();

//                       final double avgPrice =
//                           (pos['average_price'] ?? 0).toDouble();

//                       return _buildPositionCard(
//                         symbol,
//                         qty,
//                         pnl,
//                         avgPrice,
//                       );
//                     },
//                   ),
//       ),
//     );
//   }

//   Widget _buildPositionCard(
//     String symbol,
//     int qty,
//     double pnl,
//     double avgPrice,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 🔹 SYMBOL + QTY
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 symbol,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 "Qty: $qty",
//                 style: const TextStyle(fontSize: 13),
//               ),
//             ],
//           ),

//           const SizedBox(height: 8),

//           // 🔹 AVG PRICE
//           Text(
//             "Avg Price: ₹$avgPrice",
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 13,
//             ),
//           ),

//           const SizedBox(height: 10),

//           // 🔹 PNL
//           Text(
//             "P&L: ₹${pnl.toStringAsFixed(2)}",
//             style: TextStyle(
//               color: _getPnLColor(pnl),
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }