import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/api_service.dart';

class WebviewLoginScreen extends StatefulWidget {
  final AdminApi apiService;

  const WebviewLoginScreen({super.key, required this.apiService});

  @override
  State<WebviewLoginScreen> createState() => _WebviewLoginScreenState();
}

class _WebviewLoginScreenState extends State<WebviewLoginScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _isExchanging = false;
  bool _tokenHandled = false;

  static const String loginUrl =
      'https://kite.zerodha.com/connect/login?v=3&api_key=zklzzl4oa2s6b7w7';

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
            _checkUrlForToken(url);
          },
          onNavigationRequest: (request) {
            if (_checkUrlForToken(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  bool _checkUrlForToken(String url) {
    if (_tokenHandled) return false;
    debugPrint('CURRENT URL: $url');

    if (url.contains('request_token=')) {
      final uri = Uri.parse(url);
      final requestToken = uri.queryParameters['request_token'];
      debugPrint('REQUEST TOKEN FOUND: $requestToken');

      if (requestToken != null && requestToken.isNotEmpty) {
        _tokenHandled = true;
        _exchangeToken(requestToken);
        return true;
      }
    }
    return false;
  }

  Future<void> _exchangeToken(String requestToken) async {
    if (_isExchanging) return;

    debugPrint('Sending token to backend');

    setState(() {
      _isExchanging = true;
    });

    try {
      final response = await widget.apiService.exchangeToken(requestToken);
      debugPrint('BACKEND RESPONSE: $response');

      if (response.containsKey('access_token')) {
        await widget.apiService.saveToken(response['access_token'].toString());
      } else if (response.containsKey('token')) {
        await widget.apiService.saveToken(response['token'].toString());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection Successful'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, response);
    } catch (error) {
      debugPrint('EXCHANGE ERROR: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );

      setState(() {
        _isExchanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect to Zerodha')),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading || _isExchanging)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
