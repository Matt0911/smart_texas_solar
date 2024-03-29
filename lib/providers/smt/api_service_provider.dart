import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smart_texas_solar/models/billing_data.dart';
import 'dart:convert' as convert;
import 'package:smart_texas_solar/providers/smt/token_service_provider.dart';

import '../../models/smt_intervals.dart';
import '../../util/date_util.dart';
import '../hive/smt_data_store_provider.dart';

final smtApiServiceProvider = FutureProvider<SMTApiService>((ref) async {
  SMTDataStore dataStore = await ref.watch(smtDataStoreProvider.future);
  TokenService tokenController =
      await ref.watch(smtTokenServiceProvider.future);
  return SMTApiService.create(tokenController, dataStore);
});

class SMTApiService {
  final TokenService _tokenController;
  final SMTDataStore _dataStore;
  SMTApiService._create(this._tokenController, this._dataStore);

  static Future<SMTApiService> create(
    TokenService tokenController,
    SMTDataStore intervalsStore,
  ) async {
    final component = SMTApiService._create(tokenController, intervalsStore);
    return component;
  }

  final DateFormat _formatter = DateFormat('MM/dd/yyyy');

  Map<DateTime, SMTIntervals>? getIntervalsSavedForDates(
      DateTime startDate, DateTime? endDate) {
    var dates = getDateListFromRange(startDate, endDate ?? startDate);
    return _dataStore.getStoredIntervals(dates);
  }

  Future<Map<DateTime, SMTIntervals>> fetchIntervals({
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    var intervalsData = getIntervalsSavedForDates(startDate, endDate);
    if (intervalsData != null) {
      return intervalsData;
    }

    var url = Uri.https('www.smartmetertexas.com', '/api/usage/interval');
    String token = await _tokenController.token;
    String cookies = _dataStore.getCookies() ?? '';
    var response = await http.post(
      url,
      body: {
        'startDate': _formatter.format(startDate),
        'endDate': _formatter.format(endDate ?? startDate),
        'esiid': '10443720000461711', // TODO: dynamic
      },
      headers: {
        'Authorization': 'Bearer $token',
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

      var intervalsMap = SMTIntervals.splitIntoDays(jsonResponse);
      _dataStore.storeManyIntervals(intervalsMap);
      return intervalsMap;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get token');
    }
  }

  Map<DateTime, SMTIntervals>? getBillingDataSavedForDates(
      DateTime startDate, DateTime? endDate) {
    var dates = getDateListFromRange(startDate, endDate ?? startDate);
    return _dataStore.getStoredIntervals(dates);
  }

  Future<List<BillingData>> fetchBillingData() async {
    var url = Uri.https('www.smartmetertexas.com', '/api/usage/monthly');
    String token = await _tokenController.token;
    String cookies = _dataStore.getCookies() ?? '';
    DateTime twoAgo = DateTime.now().subtract(const Duration(days: 365 * 2));
    DateTime startDate = getStartOfNextMonth(twoAgo);
    DateTime endDate = getEndOfMonth(DateTime.now());

    var response = await http.post(
      url,
      body: {
        'startDate': _formatter.format(startDate),
        'endDate': _formatter.format(endDate),
        'esiid': '10443720000461711', // TODO: dynamic
      },
      headers: {
        'Authorization': 'Bearer $token',
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

      var newBillingDataList = BillingData.getBillingDataList(jsonResponse);
      var combinedBillingData = _dataStore.addBillingData(newBillingDataList);
      return combinedBillingData;
    } else {
      print('Request failed with status: ${response.statusCode}.');
      return Future.error('Failed to get token');
    }
  }
}
