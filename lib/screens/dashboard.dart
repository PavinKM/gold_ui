// adding health this code is working perfectly just backup
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'webview_login.dart';
import 'logs_screen.dart';
import '../screens/PositionsScreen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  const DashboardScreen({super.key, required this.apiService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Colors - Professional FinTech Palette
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color bgCanvas = Color(0xFFF8FAFC);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);

  bool _isTokenValid = false;
  String? _userId;
  bool _isLoadingToken = true;
  String _engineStatus = 'Unknown';
  bool _isLoadingEngineStatus = true;
  bool _isEngineActionRunning = false;

  // for health
  String _healthStatus = "UNKNOWN";
  bool _isCheckingHealth = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // widget.apiService

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchTokenStatus(), _fetchEngineStatus()]);
  }

  Future<void> _fetchTokenStatus() async {
    setState(() => _isLoadingToken = true);
    try {
      final response = await widget.apiService.getTokenStatus();
      setState(() {
        _isTokenValid = response['has_access_token'] == true;
        _userId = response['user_id'];
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
        _engineStatus = (response['status'] ?? 'Stopped').toLowerCase();
      });
    } catch (e) {
      setState(() => _engineStatus = 'error');
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
      _showSnackBar(successMsg, successGreen);
      await Future.delayed(const Duration(milliseconds: 800));
      await _fetchEngineStatus();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Action Failed: $e", dangerRed);
    } finally {
      if (mounted) setState(() => _isEngineActionRunning = false);
    }
  }

  // for health
  Future<void> _checkBackendHealth() async {
    setState(() => _isCheckingHealth = true);

    try {
      final isHealthy = await widget.apiService.getHealth();

      setState(() {
        _healthStatus = isHealthy ? "HEALTHY" : "UNHEALTHY";
      });
    } catch (e) {
      setState(() {
        _healthStatus = "ERROR";
      });
    } finally {
      setState(() => _isCheckingHealth = false);
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

  @override
  Widget build(BuildContext context) {
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
              _buildStatusGrid(),
              const SizedBox(height: 30),
              _buildSectionTitle("System Connectivity"),
              const SizedBox(height: 12),
              _buildTokenCard(),
              const SizedBox(height: 30),
              _buildHealthStatusCard(),
              const SizedBox(height: 16),
              _buildSectionTitle("Execution Controls"),
              const SizedBox(height: 12),
              _buildEngineControls(),
              const SizedBox(height: 40),
              // _buildNavigationButtons(),
              _buildPositionsButton(),
              const SizedBox(height: 12),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }
// appbar top
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Staminal EGIS',
        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 20),
      ),
      actions: [
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
          "GOLD Admin",
          style: TextStyle(color: Colors.blueGrey[900], fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          "User ID: ${_userId ?? 'Guest Session'}",
          style: TextStyle(color: Colors.blueGrey[400], fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusGrid() {
    return Row(
      children: [
        _buildQuickStat(
          "Broker Status",
          _isTokenValid ? "CONNECTED" : "DISCONNECTED",
          _isTokenValid ? successGreen : dangerRed,
          _isTokenValid ? Icons.lan : Icons.lan_outlined,
        ),
        const SizedBox(width: 16),
        _buildQuickStat(
          "Engine Mode",
          _engineStatus.toUpperCase(),
          _engineStatus == 'running' ? successGreen : Colors.blueGrey,
          _engineStatus == 'running' ? Icons.bolt : Icons.power_settings_new,
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
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
                const Text("Zerodha API Access", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  _isTokenValid ? "Token is valid for the next 24 hours" : "Authentication required to start trading",
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WebviewLoginScreen(apiService: widget.apiService))),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    final bool isHealthy = _healthStatus == "HEALTHY";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          // 🔹 LEFT SIDE (TEXT)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Backend Health",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  isHealthy
                      ? "All systems operational"
                      : _healthStatus == "ERROR"
                          ? "Server error detected"
                          : "Tap to check system health",
                  style: TextStyle(
                    color: Colors.blueGrey[400],
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 8),

                // 🔥 STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHealthy
                        ? successGreen.withOpacity(0.1)
                        : (_healthStatus == "ERROR"
                            ? dangerRed.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _healthStatus,
                    style: TextStyle(
                      color: isHealthy
                          ? successGreen
                          : (_healthStatus == "ERROR"
                              ? dangerRed
                              : Colors.orange),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 🔹 RIGHT SIDE (BUTTON / LOADER)
          _isCheckingHealth
              ? const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton.icon(
                  onPressed: _checkBackendHealth,
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text("Check"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEngineControls() {
    final bool isRunning = _engineStatus == 'running';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black,)),
              if (_isEngineActionRunning)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentIndigo)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMainActionBtn("START", Icons.play_arrow_rounded, successGreen, 
                isRunning || !_isTokenValid ? null : () => _performEngineAction(widget.apiService.startEngine, "Engine Initiated")),
              const SizedBox(width: 12),
              _buildMainActionBtn("STOP", Icons.stop_rounded, dangerRed, 
                !isRunning ? null : () => _performEngineAction(widget.apiService.stopEngine, "Engine Terminated")),
            ],
          ),
          const SizedBox(height: 12),
          _buildMainActionBtn("RESTART ENGINE", Icons.restart_alt_rounded, Colors.orange[700]!, 
            !_isTokenValid ? null : () => _performEngineAction(widget.apiService.restartEngine, "System Rebooted"), isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildMainActionBtn(String label, IconData icon, Color color, VoidCallback? onTap, {bool isFullWidth = false}) {
    final bool isDisabled = onTap == null;
    Widget btn = Material(
      color: isDisabled ? Colors.grey[100] : color.withOpacity(0.1),
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
              Text(label, style: TextStyle(color: isDisabled ? Colors.grey : color, fontWeight: FontWeight.bold, fontSize: 13)),
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
              builder: (context) => PositionsScreen(
                apiService: widget.apiService,
              ),
            ),
          );
        },
        icon: const Icon(Icons.show_chart),
        label: const Text("VIEW POSITIONS"),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogsScreen(apiService: widget.apiService))),
        icon: const Icon(Icons.article_outlined),
        label: const Text("EXAMINE SYSTEM LOGS"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title.toUpperCase(), 
      style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2));
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
      ],
    );
  }
}

  // Widget _buildPositionsButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: OutlinedButton.icon(
  //       onPressed: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => PositionsScreen(
  //               apiService: widget.apiService,
  //             ),
  //           ),
  //         );
  //       },
  //       icon: const Icon(Icons.show_chart),
  //       label: const Text("VIEW POSITIONS"),
  //       style: OutlinedButton.styleFrom(
  //         padding: const EdgeInsets.symmetric(vertical: 18),
  //         side: const BorderSide(color: Color(0xFFE2E8F0)),
  //         foregroundColor: primaryBlue,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //       ),
  //     ),
  //   );
  // } 
  

// // adding health this code is working perfectly just backup
// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import 'webview_login.dart';
// import 'logs_screen.dart';

// class DashboardScreen extends StatefulWidget {
//   final ApiService apiService;
//   const DashboardScreen({super.key, required this.apiService});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   // Colors - Professional FinTech Palette
//   static const Color primaryBlue = Color(0xFF1E3A8A);
//   static const Color accentIndigo = Color(0xFF6366F1);
//   static const Color bgCanvas = Color(0xFFF8FAFC);
//   static const Color successGreen = Color(0xFF10B981);
//   static const Color dangerRed = Color(0xFFEF4444);

//   bool _isTokenValid = false;
//   String? _userId;
//   bool _isLoadingToken = true;
//   String _engineStatus = 'Unknown';
//   bool _isLoadingEngineStatus = true;
//   bool _isEngineActionRunning = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchInitialData();
//   }

//   Future<void> _fetchInitialData() async {
//     await Future.wait([_fetchTokenStatus(), _fetchEngineStatus()]);
//   }

//   Future<void> _fetchTokenStatus() async {
//     setState(() => _isLoadingToken = true);
//     try {
//       final response = await widget.apiService.getTokenStatus();
//       setState(() {
//         _isTokenValid = response['has_access_token'] == true;
//         _userId = response['user_id'];
//       });
//     } catch (e) {
//       setState(() => _isTokenValid = false);
//     } finally {
//       setState(() => _isLoadingToken = false);
//     }
//   }

//   Future<void> _fetchEngineStatus() async {
//     setState(() => _isLoadingEngineStatus = true);
//     try {
//       final response = await widget.apiService.getEngineStatus();
//       setState(() {
//         _engineStatus = (response['status'] ?? 'Stopped').toLowerCase();
//       });
//     } catch (e) {
//       setState(() => _engineStatus = 'error');
//     } finally {
//       setState(() => _isLoadingEngineStatus = false);
//     }
//   }

//   Future<void> _performEngineAction(Future<void> Function() action, String successMsg) async {
//     if (_isEngineActionRunning) return;
//     setState(() => _isEngineActionRunning = true);

//     try {
//       await action();
//       if (!mounted) return;
//       _showSnackBar(successMsg, successGreen);
//       await Future.delayed(const Duration(milliseconds: 800));
//       await _fetchEngineStatus();
//     } catch (e) {
//       if (!mounted) return;
//       _showSnackBar("Action Failed: $e", dangerRed);
//     } finally {
//       if (mounted) setState(() => _isEngineActionRunning = false);
//     }
//   }

//   void _showSnackBar(String msg, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: bgCanvas,
//       appBar: _buildAppBar(),
//       body: RefreshIndicator(
//         onRefresh: _fetchInitialData,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildWelcomeHeader(),
//               const SizedBox(height: 25),
//               _buildStatusGrid(),
//               const SizedBox(height: 30),
//               _buildSectionTitle("System Connectivity"),
//               const SizedBox(height: 12),
//               _buildTokenCard(),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Execution Controls"),
//               const SizedBox(height: 12),
//               _buildEngineControls(),
//               const SizedBox(height: 40),
//               _buildNavigationButtons(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// // appbar top
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: Colors.white,
//       elevation: 0,
//       centerTitle: false,
//       title: const Text(
//         'Staminal EGIS',
//         style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 20),
//       ),
//       actions: [
//         IconButton(
//           onPressed: _fetchInitialData,
//           icon: const Icon(Icons.sync_rounded, color: accentIndigo),
//         ),
//         const SizedBox(width: 10),
//       ],
//     );
//   }

//   Widget _buildWelcomeHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "GOLD Admin",
//           style: TextStyle(color: Colors.blueGrey[900], fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           "User ID: ${_userId ?? 'Guest Session'}",
//           style: TextStyle(color: Colors.blueGrey[400], fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusGrid() {
//     return Row(
//       children: [
//         _buildQuickStat(
//           "Broker Status",
//           _isTokenValid ? "CONNECTED" : "DISCONNECTED",
//           _isTokenValid ? successGreen : dangerRed,
//           _isTokenValid ? Icons.lan : Icons.lan_outlined,
//         ),
//         const SizedBox(width: 16),
//         _buildQuickStat(
//           "Engine Mode",
//           _engineStatus.toUpperCase(),
//           _engineStatus == 'running' ? successGreen : Colors.blueGrey,
//           _engineStatus == 'running' ? Icons.bolt : Icons.power_settings_new,
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickStat(String label, String value, Color color, IconData icon) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             CircleAvatar(
//               backgroundColor: color.withOpacity(0.1),
//               radius: 18,
//               child: Icon(icon, color: color, size: 18),
//             ),
//             const SizedBox(height: 12),
//             Text(label, style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 4),
//             Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTokenCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDecoration(),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text("Zerodha API Access", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                 const SizedBox(height: 4),
//                 Text(
//                   _isTokenValid ? "Token is valid for the next 24 hours" : "Authentication required to start trading",
//                   style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WebviewLoginScreen(apiService: widget.apiService))),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: accentIndigo,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text("Connect"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEngineControls() {
//     final bool isRunning = _engineStatus == 'running';

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: _cardDecoration(),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black,)),
//               if (_isEngineActionRunning)
//                 const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentIndigo)),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               _buildMainActionBtn("START", Icons.play_arrow_rounded, successGreen, 
//                 isRunning || !_isTokenValid ? null : () => _performEngineAction(widget.apiService.startEngine, "Engine Initiated")),
//               const SizedBox(width: 12),
//               _buildMainActionBtn("STOP", Icons.stop_rounded, dangerRed, 
//                 !isRunning ? null : () => _performEngineAction(widget.apiService.stopEngine, "Engine Terminated")),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _buildMainActionBtn("RESTART ENGINE", Icons.restart_alt_rounded, Colors.orange[700]!, 
//             !_isTokenValid ? null : () => _performEngineAction(widget.apiService.restartEngine, "System Rebooted"), isFullWidth: true),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainActionBtn(String label, IconData icon, Color color, VoidCallback? onTap, {bool isFullWidth = false}) {
//     final bool isDisabled = onTap == null;
//     Widget btn = Material(
//       color: isDisabled ? Colors.grey[100] : color.withOpacity(0.1),
//       borderRadius: BorderRadius.circular(12),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, color: isDisabled ? Colors.grey : color, size: 20),
//               const SizedBox(width: 8),
//               Text(label, style: TextStyle(color: isDisabled ? Colors.grey : color, fontWeight: FontWeight.bold, fontSize: 13)),
//             ],
//           ),
//         ),
//       ),
//     );
//     return isFullWidth ? btn : Expanded(child: btn);
//   }

//   Widget _buildNavigationButtons() {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton.icon(
//         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogsScreen(apiService: widget.apiService))),
//         icon: const Icon(Icons.article_outlined),
//         label: const Text("EXAMINE SYSTEM LOGS"),
//         style: OutlinedButton.styleFrom(
//           padding: const EdgeInsets.symmetric(vertical: 18),
//           side: const BorderSide(color: Color(0xFFE2E8F0)),
//           foregroundColor: primaryBlue,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(title.toUpperCase(), 
//       style: TextStyle(color: Colors.blueGrey[300], fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2));
//   }

//   BoxDecoration _cardDecoration() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       border: Border.all(color: const Color(0xFFF1F5F9)),
//       boxShadow: [
//         BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
//       ],
//     );
//   }
// }
