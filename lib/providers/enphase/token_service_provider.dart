import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smart_texas_solar/providers/hive/enphase_refresh_token_provider.dart';
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/secrets_provider.dart';
import 'package:smart_texas_solar/util/navigator_key.dart';
import 'package:smart_texas_solar/widgets/enphase_auth_code_webview.dart';

final enphaseTokenServiceProvider =
    FutureProvider.autoDispose<EnphaseTokenService>((ref) {
  var secretsDB = ref.watch(secretsProvider.future);
  var refreshTokenProvider = ref.watch(enphaseRefreshTokenProvider.future);
  return EnphaseTokenService(secretsDB, refreshTokenProvider);
});

class EnphaseTokenService {
  static EnphaseTokenService? _service;
  static Future<EnphaseTokenResponse>? _currentFetch;
  final Future<HiveSecretsDB> _secretsDBFuture;
  final Future<EnphaseTokenStore> _enphaseTokenStore;

  factory EnphaseTokenService(secretsDBFuture, enphaseRefreshTokenService) {
    return _service ??=
        EnphaseTokenService.create(secretsDBFuture, enphaseRefreshTokenService);
  }

  EnphaseTokenService.create(this._secretsDBFuture, this._enphaseTokenStore);

  Future<Map<String, String>> get clientAuthHeader async {
    Secrets secrets = (await _secretsDBFuture).getSecrets();
    return {
      'authorization':
          'Basic ${base64Encode(utf8.encode('${secrets.enphaseClientId}:${secrets.enphaseClientSecret}'))}'
    };
  }

  Future<Map<String, String>> get apiKeyQuery async {
    Secrets secrets = (await _secretsDBFuture).getSecrets();
    return {'key': secrets.enphaseApiKey};
  }

  Future<EnphaseTokenResponse> _fetchTokens(String authCode) async {
    Secrets secrets = (await _secretsDBFuture).getSecrets();
    var url = Uri.https('api.enphaseenergy.com', '/oauth/token', {
      'grant_type': 'authorization_code',
      'redirect_uri': 'https://api.enphaseenergy.com/oauth/redirect_uri',
      'code': authCode,
      'URL': 'https://api.enphaseenergy.com/oauth/token'
    });
    var response = await http.post(url, headers: (await clientAuthHeader));
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      return EnphaseTokenResponse.fromData(jsonResponse);
    } else {
      return Future.error('Failed to get token');
    }
  }

  Future<EnphaseTokenResponse> _refreshTokens(String refreshToken) async {
    var url = Uri.https('api.enphaseenergy.com', '/oauth/token', {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    });
    var response = await http.post(url, headers: (await clientAuthHeader));
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      return EnphaseTokenResponse.fromData(jsonResponse);
    } else {
      return Future.error('Failed to refresh token');
    }
  }

  Future<EnphaseTokenResponse> _fetchAuthCode() async {
    Secrets secrets = (await _secretsDBFuture).getSecrets();
    String? authCode = await showDialog<String>(
      context: navigatorKey.currentContext!,
      builder: (context) =>
          EnphaseAuthCodeWebview(clientId: secrets.enphaseClientId),
    );
    if (authCode != null) {
      return await _fetchTokens(authCode);
    }
    return Future.error('error getting auth code');
  }

  void setTokens(EnphaseTokenResponse tokens) {
    // TODO investigate null error
    _enphaseTokenStore.then((store) => store.storeTokens(tokens));
  }

  Future<String> getAccessToken() async {
    EnphaseTokenResponse? tokens = (await _enphaseTokenStore).getTokens();
    if (tokens == null || JwtDecoder.isExpired(tokens.refreshToken)) {
      _currentFetch ??= _fetchAuthCode();
      EnphaseTokenResponse newTokens = await _currentFetch!;
      setTokens(newTokens);
      return newTokens.accessToken;
    } else if (JwtDecoder.isExpired(tokens.accessToken)) {
      _currentFetch ??= _refreshTokens(tokens.refreshToken);
      EnphaseTokenResponse newTokens = await _currentFetch!;
      setTokens(newTokens);
      return newTokens.accessToken;
    } else {
      return tokens.accessToken;
    }
  }
}
