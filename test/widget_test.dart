import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_ui/screens/dashboard.dart';
import 'package:gold_ui/screens/engine_state_screen.dart';
import 'package:gold_ui/services/api_service.dart';

class FakeAdminApi implements AdminApi {
  FakeAdminApi({
    required this.tokenStatus,
    required List<Map<String, dynamic>> engineStatuses,
    required List<Map<String, dynamic>> engineHealths,
    required this.engineState,
  }) : _engineStatuses = Queue<Map<String, dynamic>>.from(engineStatuses),
       _engineHealths = Queue<Map<String, dynamic>>.from(engineHealths);

  final Map<String, dynamic> tokenStatus;
  final Queue<Map<String, dynamic>> _engineStatuses;
  final Queue<Map<String, dynamic>> _engineHealths;
  final Map<String, dynamic> engineState;

  int startCalls = 0;
  int stopCalls = 0;
  int restartCalls = 0;
  int dashboardSummaryCalls = 0;
  int statusCalls = 0;

  Map<String, dynamic> _lastStatus = const {'status': 'unknown'};
  Map<String, dynamic> _lastHealth = const {'ok': false};

  @override
  Future<void> clearToken() async {}

  @override
  Future<Map<String, dynamic>> exchangeToken(String requestToken) async {
    return {'access_token': requestToken};
  }

  @override
  Future<Map<String, dynamic>> getEngineHealth() async {
    if (_engineHealths.isNotEmpty) {
      _lastHealth = _engineHealths.removeFirst();
    }
    return _lastHealth;
  }

  @override
  Future<Map<String, dynamic>> getDashboardSummary() async {
    dashboardSummaryCalls += 1;
    if (_engineStatuses.isNotEmpty) {
      _lastStatus = _engineStatuses.removeFirst();
    }
    if (_engineHealths.isNotEmpty) {
      _lastHealth = _engineHealths.removeFirst();
    }

    return {
      'engine': {
        'status': _lastStatus['status'],
        'ok': _lastHealth['ok'],
        'backend': 'docker',
        'service_name': 'engine_service',
        'last_heartbeat': _lastHealth['last_heartbeat'],
        'heartbeat_age_sec': _lastHealth['heartbeat_age_sec'],
        'heartbeat_stale': _lastHealth['heartbeat_stale'],
        'heartbeat_stale_limit_sec': _lastHealth['heartbeat_stale_limit_sec'],
      },
      'orders': {
        'open_position_exists': false,
        'pending_entry_exists': false,
        'pending_exit_exists': false,
      },
      'kite': tokenStatus,
      'position': const {'has_open_position': false, 'position': null},
      'setup': engineState,
    };
  }

  @override
  Future<Map<String, dynamic>> getEngineState({String symbol = 'GOLD'}) async {
    return engineState;
  }

  @override
  Future<Map<String, dynamic>> getEngineStatus() async {
    statusCalls += 1;
    if (_engineStatuses.isNotEmpty) {
      _lastStatus = _engineStatuses.removeFirst();
    }
    return _lastStatus;
  }

  @override
  Future<bool> getHealth() async => true;

  @override
  Future<List<String>> getLogs({int lines = 200}) async => const ['line 1'];

  @override
  Future<Map<String, dynamic>> getPositions() async {
    return const {'has_open_position': false, 'position': null};
  }

  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, dynamic>> getTokenStatus() async => tokenStatus;

  @override
  Future<Map<String, dynamic>> restartEngine() async {
    restartCalls += 1;
    return const {'status': 'restarting', 'success': true};
  }

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<Map<String, dynamic>> startEngine() async {
    startCalls += 1;
    return const {'status': 'starting', 'success': true};
  }

  @override
  Future<Map<String, dynamic>> stopEngine() async {
    stopCalls += 1;
    return const {'status': 'stopping', 'success': true};
  }
}

void main() {
  testWidgets(
    'dashboard waits for a running healthy engine before confirming start',
    (tester) async {
      final fakeApi = FakeAdminApi(
        tokenStatus: const {'has_access_token': true, 'user_id': 'ADP220'},
        engineStatuses: <Map<String, dynamic>>[
          const {'status': 'exited'},
          const {'status': 'restarting'},
          const {'status': 'running'},
        ],
        engineHealths: <Map<String, dynamic>>[
          const {'ok': false},
          const {'ok': false},
          const {'ok': true, 'heartbeat_age_sec': 1.0, 'token_loaded': true},
        ],
        engineState: const {
          'symbol': 'GOLD',
          'state_available': false,
          'market_bias': null,
          'active_setup': null,
          'recent_setup_events': [],
          'last_5m_decision': null,
          'recent_5m_decisions': [],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(
            apiService: fakeApi,
            actionPollInterval: const Duration(milliseconds: 10),
            actionTimeout: const Duration(milliseconds: 150),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('STOPPED'), findsWidgets);

      await tester.ensureVisible(find.text('START'));
      await tester.tap(find.text('START'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(fakeApi.startCalls, 1);
      expect(fakeApi.dashboardSummaryCalls, greaterThanOrEqualTo(3));
      expect(find.text('RUNNING'), findsWidgets);
      expect(find.text('Engine is running.'), findsOneWidget);
    },
  );

  testWidgets('engine state screen handles missing live setup data', (
    tester,
  ) async {
    final fakeApi = FakeAdminApi(
      tokenStatus: const {'has_access_token': true, 'user_id': 'ADP220'},
      engineStatuses: const [
        {'status': 'running'},
      ],
      engineHealths: const [
        {'ok': true},
      ],
      engineState: const {
        'symbol': 'GOLD',
        'state_available': false,
        'market_bias': null,
        'active_setup': null,
        'recent_setup_events': [],
        'last_5m_decision': null,
        'recent_5m_decisions': [],
        'setup_toast': null,
        'structure_toast': null,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EngineStateScreen(
          apiService: fakeApi,
          refreshInterval: const Duration(minutes: 30),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Waiting for live setup data'), findsOneWidget);
    expect(find.text('No active setup right now.'), findsOneWidget);
    expect(find.text('No recent 5-minute decision yet.'), findsOneWidget);
  });
}
