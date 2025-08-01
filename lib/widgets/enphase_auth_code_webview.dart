import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EnphaseAuthCodeWebview extends StatefulWidget {
  const EnphaseAuthCodeWebview({super.key, required this.clientId});

  final String clientId;

  @override
  State<EnphaseAuthCodeWebview> createState() => _EnphaseAuthCodeWebviewState();
}

class _EnphaseAuthCodeWebviewState extends State<EnphaseAuthCodeWebview> {
  final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000));

  @override
  Widget build(BuildContext context) {
    controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (request.url
              .startsWith('https://api.enphaseenergy.com/oauth/redirect_uri')) {
            print('successfully got to redirect_uri $request}');
            Uri req = Uri.parse(request.url);
            String? code = req.queryParameters['code'];
            Navigator.pop(context, code);
          }
          print('allowing navigation to $request');
          return NavigationDecision.navigate;
        },
        onProgress: (int progress) {
          print('WebView is loading (progress : $progress%)');
        },
        onPageStarted: (String url) {
          print('Page started loading: $url');
        },
        onPageFinished: (String url) {
          print('Page finished loading: $url');
        },
      ),
    );
    controller.loadRequest(
      Uri.parse(
          'https://api.enphaseenergy.com/oauth/authorize?response_type=code&client_id=${widget.clientId}&redirect_uri=https%3A%2F%2Fapi.enphaseenergy.com%2Foauth%2Fredirect_uri'),
    );
    print(
        'Build called for EnphaseAuthCodeWebview with clientId: ${widget.clientId}');
    return SizedBox(
      height: 400,
      child: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
