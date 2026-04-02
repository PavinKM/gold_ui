import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';

class WebviewLoginScreen extends StatefulWidget {
  final ApiService apiService;
  
  const WebviewLoginScreen({super.key, required this.apiService});

  @override
  State<WebviewLoginScreen> createState() => _WebviewLoginScreenState();
}

class _WebviewLoginScreenState extends State<WebviewLoginScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  bool _isExchanging = false;
  bool _tokenHandled = false;  //_checkUrlForToken() is called multiple times

  // Replace with the actual Zerodha Login URL
  static const String loginUrl = 'https://kite.zerodha.com/connect/login?v=3&api_key=zklzzl4oa2s6b7w7';

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkUrlForToken(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrlForToken(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(loginUrl));
  }

  // bool _checkUrlForToken(String url) {
  //   if (url.contains('request_token=')) {
  //     final uri = Uri.parse(url);
  //     final requestToken = uri.queryParameters['request_token'];
  //     if (requestToken != null && requestToken.isNotEmpty) {
  //       _exchangeToken(requestToken);
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  bool _checkUrlForToken(String url) {
    if (_tokenHandled) return false; //for stoping duplicate calls
    print("🌐 CURRENT URL: $url");

    if (url.contains('request_token=')) {
      final uri = Uri.parse(url);
      final requestToken = uri.queryParameters['request_token'];

      print("🔥 REQUEST TOKEN FOUND: $requestToken");

      if (requestToken != null && requestToken.isNotEmpty) {
        _exchangeToken(requestToken);
        return true;
      }
    }
    return false;
  }

  // Future<void> _exchangeToken(String requestToken) async {
  //   if (_isExchanging) return;
  //   setState(() {
  //     _isExchanging = true;
  //   });

  //   try {
  //     final response = await widget.apiService.exchangeToken(requestToken);
  //     // Assuming response contains the token, or it's implicitly saved on the backend and we get a token back.
  //     // If the backend returns it in the response:
  //     if (response.containsKey('access_token')) {
  //       await widget.apiService.saveToken(response['access_token']);
  //     } else if (response.containsKey('token')) {
  //       await widget.apiService.saveToken(response['token']);
  //     }
      
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Connection Successful'), backgroundColor: Colors.green),
  //     );
  //     Navigator.pop(context, true); // true indicates success
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
  //     );
  //     setState(() {
  //       _isExchanging = false;
  //     });
  //   }
  // }

  Future<void> _exchangeToken(String requestToken) async {
    if (_isExchanging) return;

    print("🚀 Sending token to backend: $requestToken");

    setState(() {
      _isExchanging = true;
    });

    try {
      final response = await widget.apiService.exchangeToken(requestToken);

      print("✅ BACKEND RESPONSE: $response");

      if (response.containsKey('access_token')) {
        await widget.apiService.saveToken(response['access_token']);
      } else if (response.containsKey('token')) {
        await widget.apiService.saveToken(response['token']);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection Successful'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigator.pop(context, true);
      Navigator.pop(context, response);
    } catch (e) {
      print("❌ EXCHANGE ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );

      setState(() {
        _isExchanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Zerodha'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading || _isExchanging)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
