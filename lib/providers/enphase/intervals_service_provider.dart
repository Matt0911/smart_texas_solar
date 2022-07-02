import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/providers/enphase/token_service_provider.dart';
import 'dart:convert' as convert;

final enphaseApiServiceProvider = Provider<EnphaseApiService>((ref) {
  var tokenService = ref.watch(enphaseTokenServiceProvider);
  return EnphaseApiService(tokenService);
});

class EnphaseApiService {
  final EnphaseTokenService _tokenService;
  EnphaseApiService._create(this._tokenService);

  EnphaseApiService(this._tokenService);

  static Future<EnphaseApiService> create(
      EnphaseTokenService tokenController) async {
    final component = EnphaseApiService._create(tokenController);
    // await component.fetchInterval();
    return component;
  }

  final DateFormat _formatter = DateFormat('MM/dd/yyyy');

  Future<String> _fetchSystemId(BuildContext context) async {
    var url = Uri.https('api.enphaseenergy.com', '/api/v4/systems',
        (await _tokenService.apiKeyQuery));
    String token = await _tokenService.getAccessToken(context);
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;

      return jsonResponse['systems'][0]['system_id'].toString();
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get enphase systems');
    }
  }

  Future<Map<String, dynamic>> fetchIntervals({
    required BuildContext context,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    String systemId = await _fetchSystemId(context);
    String token = await _tokenService.getAccessToken(context);
    DateTime startDateStartOfDay =
        DateTime(startDate.year, startDate.month, startDate.day);
    DateTime realEndDate = endDate ?? DateTime.now();
    DateTime endDateEndOfDay =
        DateTime(realEndDate.year, realEndDate.month, realEndDate.day + 1)
            .subtract(const Duration(seconds: 1));
    var url = Uri.https(
        'api.enphaseenergy.com', '/api/v4/systems/$systemId/rgm_stats', {
      ...(await _tokenService.apiKeyQuery),
      'start_at':
          (startDateStartOfDay.millisecondsSinceEpoch / 1000).toString(),
      'end_at': (endDateEndOfDay.millisecondsSinceEpoch / 1000).toString(),
    });
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;

      return jsonResponse;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get token');
    }
  }
}
