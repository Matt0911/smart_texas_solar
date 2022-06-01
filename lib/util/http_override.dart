import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host.isNotEmpty && host == 'smartmetertexas.com') {
          return true;
        } else {
          return false;
        }
      };
  }
}
