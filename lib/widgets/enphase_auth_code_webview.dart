import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EnphaseAuthCodeWebview extends StatefulWidget {
  const EnphaseAuthCodeWebview({Key? key, required this.clientId})
      : super(key: key);

  final String clientId;

  @override
  State<EnphaseAuthCodeWebview> createState() => _EnphaseAuthCodeWebviewState();
}

class _EnphaseAuthCodeWebviewState extends State<EnphaseAuthCodeWebview> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      child: WebView(
        initialUrl:
            'https://api.enphaseenergy.com/oauth/authorize?response_type=code&client_id=${widget.clientId}&redirect_uri=https%3A%2F%2Fapi.enphaseenergy.com%2Foauth%2Fredirect_uri',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
        onProgress: (int progress) {
          print('WebView is loading (progress : $progress%)');
        },
        // javascriptChannels: <JavascriptChannel>{
        //   _toasterJavascriptChannel(context),
        // },
        navigationDelegate: (NavigationRequest request) {
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
        onPageStarted: (String url) {
          print('Page started loading: $url');
        },
        onPageFinished: (String url) {
          print('Page finished loading: $url');
        },
        gestureNavigationEnabled: true,
        backgroundColor: const Color(0x00000000),
      ),
    );
  }
}
