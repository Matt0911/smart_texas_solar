import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:smart_texas_solar/providers/smt/token_provider.dart';

final smtIntervalsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  var token = await ref.watch(smtTokenProvider.future);
  var url = Uri.https('smartmetertexas.com', '/api/usage/interval');
  var response = await http.post(url, headers: {
    'Authorization': 'Bearer $token'
  }, body: {
    'startDate': '05/27/2022',
    'endDate': '05/28/2022',
    'esiid': '10443720000461711'
  });
  if (response.statusCode == 200) {
    var jsonResponse =
        convert.jsonDecode(response.body) as Map<String, dynamic>;

    return jsonResponse;
  } else {
    print('Request failed with status: ${response.statusCode}.');
    return Future.error('Failed to get token');
  }
});

class InvervalsController {}
