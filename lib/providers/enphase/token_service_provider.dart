import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:smart_texas_solar/providers/hive/enphase_refresh_token_provider.dart';
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/hive/secrets_provider.dart';
import 'package:smart_texas_solar/widgets/enphase_auth_code_webview.dart';

final enphaseTokenServiceProvider =
    Provider.autoDispose<EnphaseTokenService>((ref) {
  var secretsDB = ref.watch(secretsProvider.future);
  var refreshTokenProvider = ref.watch(enphaseRefreshTokenProvider.future);
  return EnphaseTokenService(secretsDB, refreshTokenProvider);
});

class EnphaseTokenService {
  static EnphaseTokenService? _service;
  static Future<EnphaseTokenResponse>? _currentFetch;
  final Future<HiveSecretsDB> _secretsDBFuture;
  final Future<EnpahseTokenStore> _enphaseTokenStore;

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

  Future<EnphaseTokenResponse> _fetchAuthCode(BuildContext context) async {
    Secrets secrets = (await _secretsDBFuture).getSecrets();
    String? authCode = await showDialog<String>(
      context: context,
      builder: (context) =>
          EnphaseAuthCodeWebview(clientId: secrets.enphaseClientId),
    );
    if (authCode != null) {
      return await _fetchTokens(authCode);
    }
    // return Future.error('error getting auth code');
    return EnphaseTokenResponse.fromData({
      "access_token":
          "eyJhbGciOiJSUzI1NiJ9.eyJhdWQiOlsib2F1dGgyLXJlc291cmNlIl0sImFwcF90eXBlIjoic3lzdGVtIiwiaXNfaW50ZXJuYWxfYXBwIjpmYWxzZSwidXNlcl9uYW1lIjoibWF0dG1hbmhhcmR0QGdtYWlsLmNvbSIsInNjb3BlIjpbInJlYWQiLCJ3cml0ZSJdLCJlbmxfY2lkIjoiIiwiZW5sX3Bhc3N3b3JkX2xhc3RfY2hhbmdlZCI6IjE2NTM0MDcwMjAiLCJleHAiOjE2NTc4NTk4MTMsImVubF91aWQiOiIyODAxNjYwIiwiYXV0aG9yaXRpZXMiOlsiUk9MRV9VU0VSIl0sImp0aSI6ImIwY2U3MDJjLTgxYmYtNGU2ZC1hYmFiLTFhZWI0NDZkZTMzYSIsImNsaWVudF9pZCI6ImQ3MTI5MDQyNDliZDQ1NTJiN2RlNjQ4NGM1M2FjOTczIn0.d9sAITa6fprCPDFAf3zMjwdUgp-omvq2dx0tGB-LXaEOxBxJyOYLkIXijguOPHI32-pSLG2S8mNtHXP2mvVBsClufHyxtB8uqJJ2RKjlh8wwOXkZ1kZQbj0Hx5zhDbzOjGAPU0UUAHLr_Zpybab0U_D0C1asB5CuyLJ56mZPK68",
      "token_type": "bearer",
      "refresh_token":
          "eyJhbGciOiJSUzI1NiJ9.eyJhcHBfdHlwZSI6InN5c3RlbSIsInVzZXJfbmFtZSI6Im1hdHRtYW5oYXJkdEBnbWFpbC5jb20iLCJlbmxfY2lkIjoiIiwiZW5sX3Bhc3N3b3JkX2xhc3RfY2hhbmdlZCI6IjE2NTM0MDcwMjAiLCJhdXRob3JpdGllcyI6WyJST0xFX1VTRVIiXSwiY2xpZW50X2lkIjoiZDcxMjkwNDI0OWJkNDU1MmI3ZGU2NDg0YzUzYWM5NzMiLCJhdWQiOlsib2F1dGgyLXJlc291cmNlIl0sImlzX2ludGVybmFsX2FwcCI6ZmFsc2UsInNjb3BlIjpbInJlYWQiLCJ3cml0ZSJdLCJhdGkiOiJiMGNlNzAyYy04MWJmLTRlNmQtYWJhYi0xYWViNDQ2ZGUzM2EiLCJleHAiOjE2NTgzNzgyMTMsImVubF91aWQiOiIyODAxNjYwIiwianRpIjoiOTUyYjFhYjEtOGUwZC00MDlmLTg4MjUtMmNhNDA3YzQ2ZmY4In0.ZoVzhEzUxU30rZACgK_nOqpOM0b1vYzdh7j_ATnapfItSm4BOo_gFQnkm03IrKLkg2eFkmVTBhjboBWTjFmFk-Lwi5I0_ODhNoYnXXHqsvPGPmuMe5rQ_yxeD72Hv8WYYUAT0dddvD1p-Y1sFh3S0edHPCfPfr0tFjX4qenYn8I",
      "expires_in": 86399,
      "scope": "read write",
      "enl_uid": "2801660",
      "enl_cid": "",
      "enl_password_last_changed": "1653407020",
      "is_internal_app": false,
      "app_type": "system",
      "jti": "b0ce702c-81bf-4e6d-abab-1aeb446de33a"
    });
  }

  setTokens(EnphaseTokenResponse tokens) {
    _enphaseTokenStore
        .then<EnpahseTokenStore>((store) => store.storeTokens(tokens));
  }

  Future<String> getAccessToken(BuildContext context) async {
    EnphaseTokenResponse? tokens = (await _enphaseTokenStore).getTokens();
    if (tokens == null || JwtDecoder.isExpired(tokens.refreshToken)) {
      _currentFetch ??= _fetchAuthCode(context);
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
