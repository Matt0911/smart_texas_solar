import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert' as convert;
import 'package:smart_texas_solar/providers/smt/token_service_provider.dart';

import '../../models/smt_intervals.dart';
import '../../util/date_util.dart';
import '../hive/smt_data_store_provider.dart';

final smtApiServiceProvider = FutureProvider<IntervalsService>((ref) async {
  TokenService tokenController =
      await ref.watch(smtTokenServiceProvider.future);
  SMTDataStore intervalsStore = await ref.watch(smtDataStoreProvider.future);
  return IntervalsService.create(tokenController, intervalsStore);
});

class IntervalsService {
  final TokenService _tokenController;
  final SMTDataStore _dataStore;
  IntervalsService._create(this._tokenController, this._dataStore);

  static Future<IntervalsService> create(
    TokenService tokenController,
    SMTDataStore intervalsStore,
  ) async {
    final component = IntervalsService._create(tokenController, intervalsStore);
    return component;
  }

  final DateFormat _formatter = DateFormat('MM/dd/yyyy');

  Future<Map<DateTime, SMTIntervals>> fetchIntervals({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    var dates = getDateListFromRange(startDate, endDate ?? startDate);

    var intervalsData = _dataStore.getStoredIntervals(dates);
    if (intervalsData != null) {
      return intervalsData;
    }

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

      var fetchedIntervals = SMTIntervals.fromData(jsonResponse);
      var intervalsMap = fetchedIntervals.splitIntoDays();
      _dataStore.storeManyIntervals(intervalsMap);
      return intervalsMap;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get token');
    }
  }
}
