import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/secrets_provider.dart';

import '../hive/smt_data_store_provider.dart';

final homeUrl = Uri.https('www.smartmetertexas.com', '/home');

final smtTokenServiceProvider = FutureProvider<TokenService>((ref) async {
  var smtStore = await ref.watch(smtDataStoreProvider.future);
  var secretsDB = await ref.watch(secretsProvider.future);
  Secrets secrets = secretsDB.getSecrets();
  return TokenService.create(secrets, smtStore);
});

class TokenService {
  final Secrets _secrets;
  final SMTDataStore _dataStore;
  TokenService._create(this._secrets, this._dataStore);
  String? _token;

  static Future<TokenService> create(
      Secrets secrets, SMTDataStore dataStore) async {
    final component = TokenService._create(secrets, dataStore);
    await component._fetchToken();
    return component;
  }

  Future<String> _fetchToken() async {
    var storedToken = _dataStore.getAccessToken();
    if (storedToken != null) return storedToken;
    _dataStore.removeCookies();
    Completer<String> getCookies = Completer();
    HeadlessInAppWebView headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: homeUrl),
      onWebViewCreated: (controller) {
        CookieManager cookieManager = CookieManager.instance();
        cookieManager.deleteAllCookies();
      },
      onLoadStop: (controller, url) async {
        CookieManager cookieManager = CookieManager.instance();
        var cookies = await cookieManager.getCookies(url: homeUrl);
        if (!getCookies.isCompleted) {
          getCookies
              .complete(cookies.map((e) => '${e.name}=${e.value}').join('; '));
        }
      },
    );
    headlessWebView.run();
    String cookies = await getCookies.future;
    headlessWebView.dispose();
    _dataStore.setCookies(cookies);
    print('i got cookies: $cookies');
    var url = Uri.https('www.smartmetertexas.com', '/api/user/authenticate');
    var response = await http.post(
      url,
      body: {
        'rememberMe': 'true',
        'username': _secrets.smtUser,
        'password': _secrets.smtPass,
      },
      headers: {
        'cookie': cookies,
        'authority': 'www.smartmetertexas.com',
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'en-US,en;q=0.9,vi;q=0.8',
        'cache-control': 'no-cache',
        // 'content-type': 'application/json;charset=UTF-8',
        'origin': 'https://www.smartmetertexas.com',
        'pragma': 'no-cache',
        'referer': 'https://www.smartmetertexas.com/home',
        'sec-ch-ua':
            '"Microsoft Edge";v="107", "Chromium";v="107", "Not=A?Brand";v="24"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.35'
      },
    );
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      _token = jsonResponse['token'];
      _dataStore.setAccessToken(_token!);
      return _token!;
    } else {
      return Future.error('Failed to get token');
    }
  }

  Future<String> get token {
    if (_token == null) {
      // TODO: or if expired
      return _fetchToken();
    } else {
      return Future.value(_token);
    }
  }
}
