import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/secrets_provider.dart';

import '../hive/smt_data_store_provider.dart';

final homeUrl = WebUri('https://www.smartmetertexas.com/home');

final smtTokenServiceProvider = FutureProvider<TokenService>((ref) async {
  var smtStore = await ref.watch(smtDataStoreProvider.future);
  var secretsDB = await ref.watch(secretsProvider.future);
  Secrets secrets = await secretsDB.getSecrets();
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
    CookieManager cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
    Completer<String> getCookies = Completer();
    HeadlessInAppWebView headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: homeUrl),
      onWebViewCreated: (controller) {
        CookieManager cookieManager = CookieManager.instance();
        cookieManager.deleteAllCookies();
      },
      shouldInterceptFetchRequest: (controller, request) async {
        print('fetch request: $request');
        return null;
      },
      shouldInterceptAjaxRequest: (controller, request) async {
        print('ajax request: $request');
        return null;
      },
      onLoadStop: (controller, url) async {
        await Future.delayed(const Duration(seconds: 2));
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
    var url =
        Uri.https('www.smartmetertexas.com', '/commonapi/user/authenticate');
    var response = await http.post(
      url,
      body: convert.jsonEncode({
        'rememberMe': 'true',
        'username': _secrets.smtUser,
        'password': _secrets.smtPass,
      }),
      headers: {
        'authority': 'www.smartmetertexas.com',
        'method': 'POST',
        'path': '/api/user/authenticate',
        'scheme': 'https',
        'accept': 'application/json, text/plain, */*',
        'accept-encoding': 'gzip, deflate, br',
        'accept-language': 'en-US,en;q=0.9,vi;q=0.8',
        'cache-control': 'no-cache',
        'content-type': 'application/json;charset=UTF-8',
        'cookie': cookies,
        // 'cookie': 'bm_sz=F5D08598E2210FC97F3CF05652E798A2~YAAQqDovF+N0PAmFAQAALbC9IRKpWKLOltMItgI5/CMvf8sL+s/ZByFTSCG8toes5Wnj+nKMxLOf4b/ozPLvXJDAFDreIePxks4NhK/62t9HBMsE6zjXA9nzUmJLHl0PV+i0mfBc6v9yJrXnbaBg5iPnI1bEM/0lX++nTpLg9PYzYFqsRXocVdAFS9hLMFaTNO1yEd2fZ3mLa83enZHkUdbFcr64y4u6E+neCwXc/eF5yTGNyPqEdEVIgIpDykAEd1rR16FUaEY9fS6AmWxyBHz/E0tQL51pDvB/X+s4pW4C/Qrl9ZEphZlJlv0=~4340019~3355717; bm_sv=3A34CC899AA02747E76E750187990B11~YAAQqDovF3l1PAmFAQAA87K9IRI1b3lm0lXgpupc9V1NqtZ30Sf+Sa1QoBo7XeZG/1xJnCPZW5iIaYGF5Vj5yYki8bnihQHWGZf4DMhe+B2rAyvyFP23fVBbOtHDu0rzDYK2WCJVlLLqcn9Acena3cXIlJapI6sDxJ8ZmjDlesECRTYibq/Vkoa1o8VAGQUqwd//t4cDdrKidhMRQOiqfjFA0HjUvdd9ut1gF5m1btI6LzWnKii5bQsvtVyUT3CEqFXTT8U3y4Mo~1; ak_bmsc=117D0B369C62F50B955F3D611E3A3830~000000000000000000000000000000~YAAQqDovF8x1PAmFAQAAMrW9IRJdlWGz7wE5armfJn4FJEHt4d2ZkPnOcEMIisHQk8OneWdkVWgSi7VxoRQPTxgrtVO7f58jQj3PMkdekiKZux73Yewremv/r2foQkopxl6TGIcC5SWh8zizJokFl4B6BH2gpx99BJJ0gcz4EqgX6C8F5kSfJJZtUWSS/9s8fnpo1LQamiIZZC4V7rkzbEO2ZhoS1ba5tiC7mrghFIbNq9WpVwkEmIiV3MTYjbRImuQ+KryKTRctRC7RKg3/E5fyvq6KFybCzZMJdItSUWsJuqZqzyk5fxENVvT/XNtZ9wvEVsGStrs6H//nVhDAgDT2e8MGf2RoAoLNjc2m7IPdDSrrgJhmgpfn2u+qfMB+YJ6Q0qCDc64espg8bkf7D5L7QfQUB56X0OKg9RqczlxZy0cpGVcJV/LLMJODfhgKrfkuwHeFFaKLF9O+aWPZ4HuTFQ8KMJpCM0wprWZIDMujdga7iUfCxdJBJj7gtPR+vOySh3mw+p6J2pzh1nNwkeM0nA9RfWU=; _abck=2F411702EF53F0386A3C4BC9EEF7F209~0~YAAQqDovF/R1PAmFAQAAILa9IQkCGhju+xi1Rn0A9z3sv9wCjn2pC6cGvBVuD0NS6hc9DSzEtWMxTohH7XBWosNvYkbC3seVp9kDSGYQl/hWYVjoov/8X7ZilJXY1tgpd3wCdDk83DKvIAqbWKygn3/EIyZ9HMG9wbwvrjRShjvwIIGbEhQVCD8cSRKsjcSQHQ412K+36qX7dI5dV7GtenkKlC9N6UMBoC1L1M8UBAWo4hpRT/gADt4BXA4AwVtnmbYkQbFqeYNS3aJhW2FFOj+Hs3MQZt810yp5YWEHTH9VO2i+Vfnz46jTvwVK+oSSc3p9FKDkQwE3iSoQpOpk7puRNQJeGwcKx7ee9TFZzm3SC3cdmW6YAuvNdgYF9F0PRK7nUNMjcw0i0Nc6eztAAkS1euE1RTIEdRFM/jpqV3EEdw==~-1~||-1||~-1',
        'origin': 'https://www.smartmetertexas.com',
        'pragma': 'no-cache',
        'referer': 'https://www.smartmetertexas.com/home',
        'sec-ch-ua':
            '"Not?A_Brand";v="8", "Chromium";v="108", "Microsoft Edge";v="108"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36 Edg/108.0.1462.54',
      },
    );
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      _token = jsonResponse['token'];
      _dataStore.setAccessToken(_token!);
      return _token!;
    } else {
      return Future.error(Exception(
          'Failed to get token\nCode: ${response.statusCode} - ${response.reasonPhrase}'));
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
