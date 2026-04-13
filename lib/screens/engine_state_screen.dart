import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class EngineStateScreen extends StatefulWidget {
  final ApiService apiService;

  const EngineStateScreen({super.key, required this.apiService});

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

    /// 🔄 Auto refresh every 5 min
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshData();
    });
  }

  void _refreshData() {
    setState(() {
      _futureData = widget.apiService.getEngineState();
    });
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
              Text("ENGINE COMMAND",
                  style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.grey)),
              SizedBox(height: 4),
              Text("Real-Time Analytics",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

            final data = snapshot.data!;
            final bias = data["market_bias"];
            final setup = data["active_setup"];
            final decision = data["last_5m_decision"];
            final toast = data["setup_toast"];
            final events = data["recent_setup_events"] ?? [];

            return RefreshIndicator(
              onRefresh: () async => _refreshData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    /// 🔔 TOAST
                    if (toast != null) _buildToast(toast),

                    _buildHeader(data["symbol"]),

                    const SizedBox(height: 20),

                    _buildSectionTitle("DECISION"),
                    _buildDecisionCard(decision),

                    const SizedBox(height: 20),

                    _buildSectionTitle("MARKET BIAS"),
                    _buildBiasCard(bias),

                    const SizedBox(height: 20),

                    _buildSectionTitle("ACTIVE SETUP"),
                    _buildSetupCard(setup),

                    const SizedBox(height: 20),

                    _buildSectionTitle("RECENT EVENTS"),
                    _buildRecentEvents(events),

                    const SizedBox(height: 30),

                    Text(
                      "Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}",
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

  /// 🔥 HEADER
  Widget _buildHeader(dynamic symbol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentColor, _accentColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            symbol?.toString() ?? "N/A",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.sensors, color: Colors.white),
        ],
      ),
    );
  }

  /// 🔥 TOAST
  Widget _buildToast(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  /// 🔥 DECISION CARD
  Widget _buildDecisionCard(Map<String, dynamic> decision) {
    final act = decision["decision"].toString();
    final color = _getDecisionColor(act);

    return _baseCard(
      child: Column(
        children: [
          Text(act,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 10),
          Text(decision["reason"]),
        ],
      ),
    );
  }

  Color _getDecisionColor(String d) {
    d = d.toUpperCase();
    if (d.contains("BUY")) return Colors.green;
    if (d.contains("SELL")) return Colors.red;
    if (d.contains("WAIT")) return Colors.orange;
    return Colors.blue;
  }

  /// 🔥 BIAS
  Widget _buildBiasCard(Map<String, dynamic> bias) {
    return _baseCard(
      child: Column(
        children: [
          _row("Trend", bias["trend"]),
          _row("ATR", bias["atr"].toString()),
          _row("Strength", bias["trend_strength"].toString()),
          _row("Armed", bias["armed"].toString()),
          _row("Source", bias["source"]),
        ],
      ),
    );
  }

  /// 🔥 SETUP FULL DATA
  // Widget _buildSetupCard(Map<String, dynamic> setup) {
  //   return _baseCard(
  //     child: Column(
  //       children: setup.entries.map<Widget>((e) {
  //         return _row(e.key, e.value.toString());
  //       }).toList(),
  //     ),
  //   );
  // }

  Widget _buildSetupCard(Map<String, dynamic> setup) {
    return Column(
      children: [

        /// 🧭 STATE INFO
        _sectionCard("STATE INFO", [
          _row("State", setup["state"]),
          _row("Bias", setup["bias"]),
          _row("Regime", setup["regime"]),
        ]),

        /// 📊 PRICE LEVELS
        _sectionCard("PRICE LEVELS", [
          _row("Ref High", setup["ref_high"]),
          _row("Ref Low", setup["ref_low"]),
          _row("Pullback Low", setup["pullback_low"]),
          _row("Close", setup["close"]),
        ]),

        /// 📉 INDICATORS
        _sectionCard("INDICATORS", [
          _row("VWAP", setup["vwap"]),
          _row("ATR", setup["atr"]),
        ]),

        /// ⏱ TIMING
        _sectionCard("TIMING", [
          _row("Expiry (sec)", setup["expiry_remaining_sec"]),
        ]),
      ],
    );
  }

  /// 🔥 EVENTS
  Widget _buildRecentEvents(List events) {
    return Column(
      children: events.map<Widget>((e) {
        return _baseCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e["EVENT"], style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${e["bias"]} | ${e["regime"]} | ${e["state"]}"),
              Text(e["ts"].toString(), style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 🔧 COMMON UI
  // Widget _row(String k, String v) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(k, style: const TextStyle(color: Colors.grey)),
  //         Text(v),
  //       ],
  //     ),
  //   );
  // }

  Widget _row(String k, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.grey)),
          Text(v?.toString() ?? "N/A"), // ✅ SAFE CONVERSION
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

  Widget _buildSectionTitle(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(t,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text(error));
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


// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for timestamps
// import '../services/api_service.dart';

// class EngineStateScreen extends StatefulWidget {
//   final ApiService apiService;

//   const EngineStateScreen({super.key, required this.apiService});

//   @override
//   State<EngineStateScreen> createState() => _EngineStateScreenState();
// }

// class _EngineStateScreenState extends State<EngineStateScreen> {
//   late Future<Map<String, dynamic>> _futureData;
//   final Color _accentColor = const Color(0xFF6366F1); // Modern Indigo
//   final Color _bgDark = const Color(0xFF0F172A);    // Slate 900
//   final Color _cardDark = const Color(0xFF1E293B);  // Slate 800

//   @override
//   void initState() {
//     super.initState();
//     _refreshData();
//   }

//   void _refreshData() {
//     setState(() {
//       _futureData = widget.apiService.getEngineState();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Theme(
//       data: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: _bgDark,
//         cardColor: _cardDark,
//         appBarTheme: AppBarTheme(backgroundColor: _bgDark, elevation: 0),
//       ),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Column(
//             children: [
//               const Text("ENGINE COMMAND", 
//                 style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.grey)),
//               const SizedBox(height: 4),
//               const Text("Real-Time Analytics", 
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           centerTitle: true,
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.history_rounded, color: Colors.grey),
//               onPressed: () {},
//             )
//           ],
//         ),
//         body: FutureBuilder<Map<String, dynamic>>(
//           future: _futureData,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator(color: Colors.indigoAccent));
//             }

//             if (snapshot.hasError) {
//               return _buildErrorState(snapshot.error.toString());
//             }

//             final data = snapshot.data!;
//             final bias = data["market_bias"];
//             final setup = data["active_setup"];
//             final decision = data["last_5m_decision"];

//             return RefreshIndicator(
//               color: _accentColor,
//               onRefresh: () async => _refreshData(),
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildHeader(data["symbol"]),
//                     const SizedBox(height: 24),
                    
//                     _buildSectionTitle("STRATEGY DECISION"),
//                     _buildDecisionCard(decision),
                    
//                     const SizedBox(height: 24),
//                     _buildSectionTitle("MARKET BIAS"),
//                     _buildBiasCard(bias),
                    
//                     const SizedBox(height: 24),
//                     _buildSectionTitle("ACTIVE SETUP METRICS"),
//                     _buildSetupCard(setup),
                    
//                     const SizedBox(height: 40),
//                     Center(
//                       child: Text(
//                         "Last updated: ${DateFormat('HH:mm:ss').format(DateTime.now())}",
//                         style: const TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   /// 🟢 HEADER WITH SYMBOL
//   Widget _buildHeader(String symbol) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(colors: [_accentColor, _accentColor.withOpacity(0.7)]),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(symbol, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
//               const Text("Instrument Active", style: TextStyle(color: Colors.white70)),
//             ],
//           ),
//           const Icon(Icons.sensors, color: Colors.white, size: 32),
//         ],
//       ),
//     );
//   }

//   /// 🔴 DECISION CARD (The Hero Card)
//   Widget _buildDecisionCard(Map<String, dynamic> decision) {
//     final String act = decision["decision"].toString().toUpperCase();
//     final bool isBuy = act.contains("BUY") || act.contains("LONG");
//     final bool isSell = act.contains("SELL") || act.contains("SHORT");
//     final Color stateColor = isBuy ? Colors.greenAccent : (isSell ? Colors.redAccent : Colors.amberAccent);

//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: _cardDark,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: stateColor.withOpacity(0.3), width: 1),
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Icon(Icons.gavel_rounded, color: stateColor),
//               const SizedBox(width: 12),
//               Text(act, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: stateColor)),
//             ],
//           ),
//           const Divider(height: 30, color: Colors.white10),
//           Text(
//             decision["reason"],
//             style: const TextStyle(color: Colors.white70, height: 1.4),
//           ),
//         ],
//       ),
//     );
//   }

//   /// 🟡 BIAS CARD
//   Widget _buildBiasCard(Map<String, dynamic> bias) {
//     return _baseCard(
//       child: Column(
//         children: [
//           _row(Icons.trending_up, "Trend", bias["trend"], 
//               color: bias["trend"].toString().toLowerCase() == "long" ? Colors.green : Colors.red),
//           _row(Icons.analytics, "Strength", "${bias["trend_strength"]}%"),
//           _row(Icons.security, "Armed Status", bias["armed"].toString(), 
//               color: bias["armed"] == true ? Colors.blueAccent : Colors.grey),
//           _row(Icons.source, "Signal Source", bias["source"]),
//         ],
//       ),
//     );
//   }

//   /// 🔵 SETUP CARD
//   Widget _buildSetupCard(Map<String, dynamic> setup) {
//     return _baseCard(
//       child: GridView.count(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         crossAxisCount: 2,
//         childAspectRatio: 2.5,
//         children: [
//           _gridItem("State", setup["state"]),
//           _gridItem("Regime", setup["regime"]),
//           _gridItem("Expiry", "${setup["expiry_remaining_sec"]}s"),
//           _gridItem("VWAP", setup["vwap"].toString()),
//           _gridItem("Ref High", setup["ref_high"].toString()),
//           _gridItem("Ref Low", setup["ref_low"].toString()),
//         ],
//       ),
//     );
//   }

//   /// 🛠 UI COMPONENTS
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 4, bottom: 8),
//       child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.2)),
//     );
//   }

//   Widget _baseCard({required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _cardDark,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: child,
//     );
//   }

//   Widget _row(IconData icon, String label, String value, {Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: Colors.white24),
//           const SizedBox(width: 12),
//           Text(label, style: const TextStyle(color: Colors.white60)),
//           const Spacer(),
//           Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
//         ],
//       ),
//     );
//   }

//   Widget _gridItem(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
//         const SizedBox(height: 2),
//         Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
//       ],
//     );
//   }

//   Widget _buildErrorState(String error) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
//           const SizedBox(height: 16),
//           Text("Connection Lost", style: Theme.of(context).textTheme.titleLarge),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(onPressed: _refreshData, child: const Text("Retry")),
//         ],
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import '../services/api_service.dart';

// class EngineStateScreen extends StatefulWidget {
//   final ApiService apiService;

//   const EngineStateScreen({super.key, required this.apiService});

//   @override
//   State<EngineStateScreen> createState() => _EngineStateScreenState();
// }

// class _EngineStateScreenState extends State<EngineStateScreen> {

//   late Future<Map<String, dynamic>> _futureData;

//   @override
//   void initState() {
//     super.initState();
//     _futureData = widget.apiService.getEngineState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Engine State"),
//         centerTitle: true,
//       ),

//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _futureData,
//         builder: (context, snapshot) {

//           /// 🔄 LOADING
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           /// ❌ ERROR
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }

//           final data = snapshot.data!;

//           final bias = data["market_bias"];
//           final setup = data["active_setup"];
//           final decision = data["last_5m_decision"];

//           return RefreshIndicator(
//             onRefresh: () async {
//               setState(() {
//                 _futureData = widget.apiService.getEngineState();
//               });
//             },

//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [

//                   /// 🔹 SYMBOL
//                   _card(
//                     title: "Symbol",
//                     child: Text(
//                       data["symbol"],
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),

//                   /// 🔹 MARKET BIAS
//                   _card(
//                     title: "Market Bias",
//                     child: Column(
//                       children: [
//                         _row("Trend", bias["trend"]),
//                         _row("ATR", bias["atr"].toString()),
//                         _row("Strength", bias["trend_strength"].toString()),
//                         _row("Armed", bias["armed"].toString()),
//                         _row("Source", bias["source"]),
//                       ],
//                     ),
//                   ),

//                   /// 🔹 ACTIVE SETUP
//                   _card(
//                     title: "Active Setup",
//                     child: Column(
//                       children: [
//                         _row("State", setup["state"]),
//                         _row("Bias", setup["bias"]),
//                         _row("Regime", setup["regime"]),
//                         _row("Expiry", "${setup["expiry_remaining_sec"]} sec"),
//                         _row("ATR", setup["atr"].toString()),
//                         _row("Ref High", setup["ref_high"].toString()),
//                         _row("Ref Low", setup["ref_low"].toString()),
//                         _row("Pullback Low", setup["pullback_low"].toString()),
//                         _row("VWAP", setup["vwap"].toString()),
//                         _row("Close", setup["close"].toString()),
//                       ],
//                     ),
//                   ),

//                   /// 🔹 DECISION
//                   _card(
//                     title: "Last 5m Decision",
//                     child: Column(
//                       children: [
//                         _row("Decision", decision["decision"]),
//                         _row("Reason", decision["reason"]),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   /// 🔹 CARD UI
//   Widget _card({required String title, required Widget child}) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             child,
//           ],
//         ),
//       ),
//     );
//   }

//   /// 🔹 ROW UI
//   Widget _row(String key, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(key, style: const TextStyle(color: Colors.grey)),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';

// class EngineStateScreen extends StatelessWidget {
//   const EngineStateScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 🔥 Mock data (same as your API)
//     final data = {
//       "symbol": "GOLD",
//       "state_available": true,
//       "market_bias": {
//         "trend": "BUY",
//         "atr": 455.28,
//         "trend_strength": 3,
//         "armed": true,
//         "source": "FIRST_15M_CONFIRM",
//       },
//       "active_setup": {
//         "state": "TRACKING",
//         "bias": "BUY",
//         "regime": "EXPANSION",
//         "expiry_remaining_sec": 600,
//         "atr": 455.28,
//         "ref_high": 153156,
//         "ref_low": 152700,
//         "pullback_low": 153034,
//         "vwap": 153028.5,
//         "close": 153120,
//       },
//       "last_5m_decision": {
//         "decision": "VALID",
//         "reason": "STRUCT_VALID"
//       }
//     };

//     final bias = data["market_bias"] as Map<String, dynamic>;
//     final setup = data["active_setup"] as Map<String, dynamic>;
//     final decision = data["last_5m_decision"] as Map<String, dynamic>;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Engine State"),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [

//             /// 🔹 SYMBOL CARD
//             _card(
//               title: "Symbol",
//               child: Text(
//                 data["symbol"].toString(),
//                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//             ),

//             /// 🔹 MARKET BIAS
//             _card(
//               title: "Market Bias",
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _row("Trend", bias["trend"]),
//                   _row("ATR", bias["atr"].toString()),
//                   _row("Strength", bias["trend_strength"].toString()),
//                   _row("Armed", bias["armed"].toString()),
//                   _row("Source", bias["source"]),
//                 ],
//               ),
//             ),

//             /// 🔹 ACTIVE SETUP
//             _card(
//               title: "Active Setup",
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _row("State", setup["state"]),
//                   _row("Bias", setup["bias"]),
//                   _row("Regime", setup["regime"]),
//                   _row("Expiry", "${setup["expiry_remaining_sec"]} sec"),
//                   _row("ATR", setup["atr"].toString()),
//                   _row("Ref High", setup["ref_high"].toString()),
//                   _row("Ref Low", setup["ref_low"].toString()),
//                   _row("Pullback Low", setup["pullback_low"].toString()),
//                   _row("VWAP", setup["vwap"].toString()),
//                   _row("Close", setup["close"].toString()),
//                 ],
//               ),
//             ),

//             /// 🔹 DECISION
//             _card(
//               title: "Last 5m Decision",
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _row("Decision", decision["decision"]),
//                   _row("Reason", decision["reason"]),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// 🔹 REUSABLE CARD
//   Widget _card({required String title, required Widget child}) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 3,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//                 style: const TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             child,
//           ],
//         ),
//       ),
//     );
//   }

//   /// 🔹 KEY-VALUE ROW
//   Widget _row(String key, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(key, style: const TextStyle(color: Colors.grey)),
//           Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
// }