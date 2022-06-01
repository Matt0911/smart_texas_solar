import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/secrets_provider.dart';

final smtTokenProvider = FutureProvider<String>((ref) async {
  var secretsDB = await ref.watch(secretsProvider.future);
  Secrets secrets = secretsDB.getSecrets();
  var url = Uri.https('smartmetertexas.com', '/api/user/authenticate');
  var response = await http.post(url, body: {
    'rememberMe': 'true',
    'username': secrets.smtUser,
    'password': secrets.smtPass,
  });
  if (response.statusCode == 200) {
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;
    var token = jsonResponse['token'];
    return token;
  } else {
    return Future.error('Failed to get token');
  }
});
