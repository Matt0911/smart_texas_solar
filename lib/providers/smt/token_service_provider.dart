import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/secrets_provider.dart';

final smtTokenServiceProvider = FutureProvider<TokenService>((ref) async {
  var secretsDB = await ref.watch(secretsProvider.future);
  Secrets secrets = secretsDB.getSecrets();
  return TokenService.create(secrets);
});

class TokenService {
  final Secrets _secrets;
  TokenService._create(this._secrets);
  String? _token;

  static Future<TokenService> create(Secrets secrets) async {
    final component = TokenService._create(secrets);
    await component._fetchToken();
    return component;
  }

  Future<String> _fetchToken() async {
    var url = Uri.https('smartmetertexas.com', '/api/user/authenticate');
    var response = await http.post(url, body: {
      'rememberMe': 'true',
      'username': _secrets.smtUser,
      'password': _secrets.smtPass,
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      _token = jsonResponse['token'];
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
