import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert' as convert;
import 'package:smart_texas_solar/providers/smt/token_service_provider.dart';

final smtIntervalsServiceProvider =
    FutureProvider<IntervalsService>((ref) async {
  TokenService tokenController =
      await ref.watch(smtTokenServiceProvider.future);
  return IntervalsService.create(tokenController);
});

class IntervalsService {
  final TokenService _tokenController;
  IntervalsService._create(this._tokenController);

  static Future<IntervalsService> create(TokenService tokenController) async {
    final component = IntervalsService._create(tokenController);
    // await component.fetchInterval();
    return component;
  }

  final DateFormat _formatter = DateFormat('MM/dd/yyyy');

  Future<Map<String, dynamic>> fetchInterval({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    var url = Uri.https('smartmetertexas.com', '/api/usage/interval');
    String token = await _tokenController.token;
    var response = await http.post(url, headers: {
      'Authorization': 'Bearer $token'
    }, body: {
      'startDate': _formatter.format(startDate),
      'endDate': _formatter.format(endDate ?? startDate),
      'esiid': '10443720000461711', // TODO: dynamic
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
